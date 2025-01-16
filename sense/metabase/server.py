import importlib
import logging
from http import HTTPStatus
from pathlib import Path
from typing import Optional, Type

import chainlit as cl
import chainlit.data as cl_data
from chainlit.data.sql_alchemy import SQLAlchemyDataLayer
from chainlit.server import app
from langchain.agents import AgentExecutor
from starlette.middleware.base import _StreamingResponse
from starlette.requests import Request
from starlette.responses import HTMLResponse

from sense.common.config import settings
from sense.common.storage_clients import (
    NullStorageClient,
    S3StorageClient,
)
from sense.metabase.agent_guided import create_guided_agent, \
    invoke_agent_with_msg, get_memory
from sense.metabase.authz import BaseAuthorizationProvider
from sense.metabase.consts import CSP, ONE_YEAR_IN_SECONDS, \
    MAX_ROWS_IN_CHAT_WINDOW
from sense.metabase.guardrail import run_guardrails
from sense.metabase.tools import (
    ListDatasetsTool,
    ListDatasetsHumanFriendlyShowToUserTool,
    CreateMetabaseQuestionTool
)
from sense.metabase.data import DataPreview
from sense.metabase.ui.data import get_downloadable_file
from sense.metabase.ui.settings import get_chat_settings_options

logger = logging.getLogger(__name__)

ROOT_DIR = Path(__file__).parent.parent

if settings.lit_database_url:
    storage_client: cl_data.BaseStorageClient
    if settings.result_storage_bucket_name:
        storage_client = S3StorageClient(settings.result_storage_bucket_name)
    else:
        storage_client = NullStorageClient()

    cl_data._data_layer = SQLAlchemyDataLayer(
        conninfo=settings.lit_database_url.get_secret_value(),
        storage_provider=storage_client,
    )

PROFILE_AUTONOMOUS_AGENT = "Autonomous Agent"
PROFILE_GUIDED_AGENT = "Guided Agent"
NO_DATABASE_ACCESS_ERROR_MESSAGE = (
    "Unfortunately, you do not have access to any databases. Please contact "
    "the admins and refresh the page."
)


@cl.on_chat_start
async def on_chat_start():
    logger.info('on_chat_start')

    if settings.db_whitelist_enabled:
        has_db_access = cl.user_session.get("user", {}).metadata["db_ids"]
        logger.info('User: %s, DB access: %s', cl.user_session.get("user"), has_db_access)
        if not has_db_access:
            await cl.Message(content=NO_DATABASE_ACCESS_ERROR_MESSAGE).send()
            return

    chat_settings = await get_chat_settings_options()
    if not chat_settings:
        await cl.Message(content=NO_DATABASE_ACCESS_ERROR_MESSAGE).send()
        return

    current_settings = await chat_settings.send()
    await setup_agent(current_settings)
    await cl.Message(content="Go ahead, ask a question!").send()


@cl.on_settings_update
async def setup_agent(_):
    memory = get_memory(num_of_messages_in_memory=10)

    tool_kwargs = get_tool_kwargs()

    tools = [
        ListDatasetsTool(**tool_kwargs),
        ListDatasetsHumanFriendlyShowToUserTool(**tool_kwargs),
        CreateMetabaseQuestionTool(
            **tool_kwargs,
            on_preview_done=render_data_preview,
        ),
    ]

    agent = create_guided_agent(memory=memory, tools=tools)

    cl.user_session.set("memory", memory)
    cl.user_session.set("agent", agent)


def get_tool_kwargs():
    return dict(
        database_id=int(
            cl.user_session.get("chat_settings").get("database_id")
        ),
        user_id=getattr(cl.user_session.get("user"), "identifier", None),
        allowed_database_ids=cl.user_session.get("user").metadata["db_ids"]
    )


async def render_data_preview(data_preview: DataPreview):
    df = data_preview.df
    sql_query = data_preview.sql_query

    if df.empty:
        await cl.Message(content=(
            f"The query has returned no rows at all. "
            f"This could imply no records really satisfy the conditions mentioned, "
            f"**or** perhaps the underlying data is unclean **or** my query referenced "
            f"the wrong data fields. Feel free to ask me for a list of possible "
            f"reasons. \n\n"
            f"```sql\n{sql_query}\n```")).send()
        return

    df_truncated = df.head(20)
    table = df_truncated.to_markdown(index=False)

    message = cl.Message(
        content="#### SQL Query Used\n"
                "> ⚠️ Please check if the correct data fields and tables have been "
                "used for this query.\n"
                "```sql\n"
                "{sql_query}\n"
                "```\n"
                "#### First {row_count} of {total_rows} rows (Truncated)\n"
                "{table}\n\nNote: Currently you can only download the first "
                "{max_rows} rows".format(
            row_count=df_truncated.shape[0],
            total_rows=df.shape[0],
            table=table,
            sql_query=sql_query,
            max_rows=MAX_ROWS_IN_CHAT_WINDOW,
        ),
        elements=[
            get_downloadable_file(df),
        ],
    )
    await message.send()


@cl.on_message
async def on_message(message: cl.Message):
    logger.info('on_message')
    if settings.db_whitelist_enabled:
        has_db_access = cl.user_session.get("user", {}).metadata["db_ids"]
        logger.info('User: %s, DB access: %s', cl.user_session.get("user"), has_db_access)
        if not has_db_access:
            await cl.Message(content=NO_DATABASE_ACCESS_ERROR_MESSAGE).send()
            return

    chat_settings = await get_chat_settings_options()
    if not chat_settings:
        await cl.Message(content=NO_DATABASE_ACCESS_ERROR_MESSAGE).send()
        return

    try:
        is_message_data_related = (
                                      not settings.guardrail_enabled
                                  ) or await run_guardrails(message)
        if is_message_data_related:
            await _invoke_agent(message)
        else:
            await cl.Message(
                content="Hi there! You can ask me questions about the active "
                        "dataset!"
            ).send()

    except Exception as e:
        await cl.ErrorMessage(content=str(e)).send()
        raise

async def _invoke_agent(message: cl.Message):
    agent: AgentExecutor = cl.user_session.get("agent")

    tool_kwargs = get_tool_kwargs()
    database_schema = await ListDatasetsTool(**tool_kwargs).ainvoke(
        input={})  # type: ignore

    await invoke_agent_with_msg(
        agent,
        {"input": message.content, "database_schema": database_schema},
        user_id=getattr(cl.user_session.get("user"), "identifier", None),
        session_id=cl.user_session.get("id", default=None),
    )


if settings.oauth_cognito_domain:
    authz_module = importlib.import_module("sense.metabase.authz")

    if not settings.db_whitelist_provider:
        raise EnvironmentError("DB_WHITELIST_PROVIDER missing")

    provider_class: Type[BaseAuthorizationProvider] = getattr(
        authz_module, settings.db_whitelist_provider
    )
    provider = provider_class()

    @cl.oauth_callback
    async def oauth_callback(
            provider_id: str,
            token: str,
            raw_user_data: dict[str, str],
            default_user: cl.User,
    ) -> Optional[cl.User]:
        logger.info('oauth_callback')
        db_ids = []

        if settings.db_whitelist_enabled:
            db_ids = await provider.get_whitelisted_db_ids(
                {
                    "provider_id": provider_id,
                    "token": token,
                    "raw_user_data": raw_user_data,
                    "default_user": default_user,
                }
            )
            logger.info('User: %s, db_ids: %s', default_user, db_ids)

        default_user.metadata.update({"db_ids": db_ids})
        return default_user


@app.middleware("http")
async def add_csp_and_cors_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["Content-Security-Policy"] = CSP
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["User-Agent"] = request.headers.get(
        "User-Agent", "DefaultUserAgent"
    )

    if not settings.chainlit_url:
        return response

    app_url = str(settings.chainlit_url)
    response.headers["Access-Control-Allow-Origin"] = app_url

    # Ref: https://https.cio.gov/hsts/
    if app_url.startswith("https://"):
        response.headers["Strict-Transport-Security"] = (
            f"max-age={ONE_YEAR_IN_SECONDS}; includeSubDomains; preload"
        )

    return response


@app.middleware("http")
async def respond_friendly_unauthorized(request: Request, call_next):
    response: _StreamingResponse = await call_next(request)

    if response.status_code == HTTPStatus.UNAUTHORIZED:
        template = ROOT_DIR / 'templates' / 'unauthorized.html'
        with open(template) as f:
            return HTMLResponse(
                content=f.read(),
                status_code=HTTPStatus.UNAUTHORIZED
            )

    return response
