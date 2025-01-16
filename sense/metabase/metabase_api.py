import logging
from typing import TypedDict, Optional, Any

import httpx
import jq

from sense.common.config import settings

# MAJOR NOTE
# EVERYTHING IN THIS FILE IS A HACK
# Okay, so most of the functionality used here are internal metabase APIs
# There is no guarantee these APIs will remain stable release-after-release
# The Metabase Teams say so as well.


X_METABASE_SESSION = "X-Metabase-Session"
MAX_ROW_COUNT = 2000

client = httpx.AsyncClient(
    base_url=str(settings.metabase_url),
    headers={
        "User-Agent": "Sense",
        "x-api-key": settings.metabase_api_key,
    },
    timeout=httpx.Timeout(timeout=settings.metabase_http_timeout),
)


class GetDatabasesResponse(TypedDict):
    id: int
    name: str


async def get_databases() -> list[GetDatabasesResponse]:
    """
    Fetch the list of databases from Metabase.
    """
    response = await client.get("/api/database")

    response.raise_for_status()

    jqed = (
        jq.compile(".data | map({id: .id, name: .name}) | sort")
        .input_value(response.json())
        .first()
    )

    return jqed


async def list_datasets(database_id) -> dict:
    response = await client.get(
        f"/api/database/{database_id}/metadata",
        params={"include_hidden": "false", "remove_inactive": "true"},
    )
    response.raise_for_status()
    return response.json()


async def create_metabase_question(
    description, query_title, sql_query, database_id
):
    question_payload = {
        "name": query_title,
        "description": description,
        "type": "question",
        "dataset_query": {
            "type": "native",
            "native": {"query": sql_query, "template-tags": {}},
            "database": database_id,
        },
        "display": "table",
        "database": database_id,
        "visualization_settings": {},
    }

    response = await client.post(url="/api/card", json=question_payload)

    response.raise_for_status()

    return response.json()


async def delete_metabase_question(existing_card_id: str | int) -> dict:
    question_payload = {"archived": True}
    response = await client.put(
        url=f"/api/card/{existing_card_id}", json=question_payload
    )

    response.raise_for_status()

    data = response.json()
    if not data["archived"]:
        raise ValueError(f"Card {existing_card_id} was not archived")

    return data


async def run_card_query(card_id: int) -> dict:
    """
    Execute a Metabase card query and return the result as a dictionary.

    :param card_id: The ID of the Metabase card to run.
    :return: The result of the query.
    """
    response = await client.post(f"/api/card/{card_id}/query")

    response.raise_for_status()

    return response.json()


class ColumnDefinition(TypedDict):
    base_type: str
    display_name: str
    name: str
    semantic_type: Optional[str]
    fingerprint: dict


class DatasetExecuteResponseData(TypedDict):
    cols: list[ColumnDefinition]
    results_metadata: list[ColumnDefinition]
    rows: list[Any]


class DatasetExecuteResponse(TypedDict):
    row_count: int
    running_count: int
    data: DatasetExecuteResponseData

    error: Optional[str]
    error_type: Optional[str]


async def run_card_query_limit_rows(
    card_id: int, row_count: int = MAX_ROW_COUNT
) -> DatasetExecuteResponse:
    """
    Execute a Metabase card query and return the result as a dictionary.
    Results limited to the specified number of rows

    :param card_id: The ID of the Metabase card to run.
    :param row_count: The number of rows to return
    :return: The result of the query.
    """

    database_id = (await get_card_metadata(card_id))["database_id"]

    data = {
        "database": database_id,
        "type": "query",
        "query": {
            # no this API does not support offsetting :cries:
            "limit": row_count,
            # This is super-undocumented behaviour
            "source-table": "card__{}".format(card_id),
        },
        "parameters": [],
    }

    response = await client.post(
        "/api/dataset",
        json=data,
    )

    response.raise_for_status()

    return response.json()


class CardMetadataResponse(TypedDict):
    database_id: int


async def get_card_metadata(card_id: int) -> CardMetadataResponse:
    response = await client.get(f"/api/card/{card_id}")

    response.raise_for_status()
    return response.json()


async def find_enum_values(field_id: int) -> list[str | int | float | bool]:
    """
    Return the enum values for any categorical field
    :param field_id: The ID of the field to find enum values for
    :return: A list of enum values
    """
    response = await client.get(f"/api/field/{field_id}/values")
    response.raise_for_status()
    data = response.json()

    if data["has_more_values"] is True:
        logging.error(
            f"Field ID {field_id} has more values than fit in context"
        )

    return [v[0] for v in data["values"]]
