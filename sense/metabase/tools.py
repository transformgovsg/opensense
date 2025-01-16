import asyncio
from typing import Any, Iterable, Dict, Optional, Awaitable
from typing import Callable

import chainlit as cl
import httpx
import jq
import sqlparse
from langchain_core.tools import BaseTool, ToolException
from pydantic.v1 import BaseModel, Field

from sense.common.config import settings
from sense.common.rate_limiter import rate_limiter
from sense.metabase import metabase_api
from sense.metabase.consts import (
    METABASE_METADATA_QUERY,
    FORMAT_USER_METADATA_QUERY,
    FORMAT_USER_METADATA_DESC_QUERY,
)
from sense.metabase.exceptions import LLMGoofed
from sense.metabase.data import DataPreview, get_data_preview


async def add_enum_values_to_fields(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Add enum values to fields in the given data dictionary.

    Args:
        data (Dict[str, Any]): The data containing tables and fields.

    Returns:
        Dict[str, Any]: The updated data with enum values added to fields.
    """

    async def process_field(field_: Dict[str, Any]) -> None:
        if field_.get("semantic_type") == "type/Category":
            enum_values = await metabase_api.find_enum_values(field_["id"])
            field_["enums"] = enum_values

    tasks = []
    tables = data.get("tables", [])
    for table in tables:
        for field in table.get("fields", []):
            tasks.append(process_field(field))

    await asyncio.gather(*tasks)
    return data


class DatabaseAccessCheckedTool(BaseTool):
    """Base class for tools that require database access checks."""

    allowed_database_ids: list[int]

    def _run(self, *args: Any, **kwargs: Any) -> Any:
        raise NotImplementedError("Only async runs are supported.")

    def check_db_whitelisted(self, database_id: int) -> None:
        """
        Check if the given database ID is whitelisted for the user.

        Args:
            database_id (int): The ID of the database to check.

        Raises:
            SystemError: If the user is not allowed access to the database.
        """
        if not settings.db_whitelist_enabled:
            return

        if database_id not in self.allowed_database_ids:
            raise SystemError("User not allowed access to this database.")


class ListDatasetsTool(DatabaseAccessCheckedTool, BaseTool):
    """Tool for listing available database tables and their columns."""

    name = "list_datasets"
    description = "Get a list of all available database tables and their columns"
    handle_tool_error = True

    database_id: int

    def _run(self, *args: Any, **kwargs: Any) -> Any:
        raise NotImplementedError("Only async runs are supported.")

    async def _arun(self, *args: Any, **kwargs: Any) -> str:
        self.check_db_whitelisted(self.database_id)

        response = await metabase_api.list_datasets(self.database_id)
        response = await add_enum_values_to_fields(response)

        jqed = jq.compile(METABASE_METADATA_QUERY).input_value(response).all()

        return "\n".join(jqed)


class ListDatasetsHumanFriendlyShowToUserTool(DatabaseAccessCheckedTool,
                                              BaseTool):
    """Tool for showing a user-friendly list of datasets to the user."""

    name = "list_datasets_human_friendly_show_to_user"
    description = (
        "Calling this function will show a SHOW TABLES-like description of "
        "the datasets or tables to the user."
    )
    handle_tool_error = True

    database_id: int

    def _run(self, *args: Any, **kwargs: Any) -> Any:
        raise NotImplementedError("Only async runs are supported.")

    async def _arun(self, *args: Any, **kwargs: Any) -> str:
        self.check_db_whitelisted(self.database_id)

        response = await metabase_api.list_datasets(self.database_id)

        template = (
            FORMAT_USER_METADATA_DESC_QUERY
            if settings.show_field_desc_to_human_enabled
            else FORMAT_USER_METADATA_QUERY
        )

        jqed = jq.compile(template).input_value(response).all()
        content = "\n".join(jqed)

        await cl.Message(content=content).send()

        return (
            "The table/dataset metadata has been successfully shown to user. "
            "You don't need to do anything"
        )


class CreateMetabaseQuestionInput(BaseModel):
    """Input model for creating a Metabase question."""

    query_title: str = Field(description="The title or name of the query")
    description: str = Field(description="Methodology of SQL Query")
    sql_query: str = Field(description="The actual SQL query")


class CreateMetabaseQuestionTool(DatabaseAccessCheckedTool, BaseTool):
    """Tool for creating a Metabase question from a SQL query."""

    name = "create_metabase_question"
    description = (
        "Run the SQL query and show the results to the user."
    )
    args_schema = CreateMetabaseQuestionInput
    handle_tool_error = True

    database_id: int
    user_id: str

    on_preview_done: Optional[Callable[[DataPreview], Awaitable[None]]]

    def _run(self, query_title: str, description: str, sql_query: str) -> Any:
        raise NotImplementedError("Only async runs are supported.")

    async def _arun(self, query_title: str, description: str,
                    sql_query: str) -> str:
        self.check_rate_limits()
        self.check_db_whitelisted(self.database_id)

        sql_query = sqlparse.format(
            sql=sql_query,
            reindent=True,
            keyword_case="upper",
        )

        try:
            response = await metabase_api.create_metabase_question(
                description, query_title, sql_query, self.database_id
            )

            if not response.get("id"):
                raise ValueError("Metabase API call failed, no ID retrieved")
        except httpx.TimeoutException:
            raise ToolException("The SQL Query timed out, it took too long.")

        if self.on_preview_done is not None:
            await self.fetch_preview(response, sql_query)

        return (
            "The response has been shown to the user. "
            "You don't need to do anything."
        )

    async def fetch_preview(self, response, sql_query):
        try:
            data_preview = await get_data_preview(response["id"], sql_query)
            await self.on_preview_done(data_preview)
        except LLMGoofed as e:
            await metabase_api.delete_metabase_question(response["id"])

            raise ToolException(
                f"Your query caused an error. \n{str(e)}\n"
                "Explain the error and try again. "
                "If you need some info you can ask, otherwise try again."
            )

    def check_rate_limits(self) -> None:
        """Check if the user has exceeded the rate limit."""
        if settings.rate_limit_enabled:
            # conditions checks if requests is from a user and not a bot
            if self.user_id and not rate_limiter.is_allowed(self.user_id):
                interval = settings.rate_limit_interval
                raise ToolException(
                    f"Rate Limit Exceeded. "
                    f"Tell the user to try again after {interval} minutes. "
                    f"You cannot auto-retry, the user must resend the message."
                )
