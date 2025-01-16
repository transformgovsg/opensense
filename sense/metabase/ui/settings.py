from typing import Iterable

import chainlit as cl
from chainlit.input_widget import Select

from sense.common.config import settings
from sense.metabase import metabase_api
from sense.metabase.metabase_api import GetDatabasesResponse


async def get_chat_settings_options() -> cl.ChatSettings | None:
    database_list: Iterable[GetDatabasesResponse] = (
        await metabase_api.get_databases()
    )

    if settings.db_whitelist_enabled:
        database_list = filter(
            lambda db: (
                db["id"] in cl.user_session.get("user").metadata["db_ids"]
            ),
            database_list,
        )

    databases = {db["name"]: str(db["id"]) for db in database_list}

    if not databases:
        return None

    first_database = next(iter(databases.values()))

    chat_settings = cl.ChatSettings(
        [
            Select(
                id="database_id",
                label="Choose Database",
                items=databases,
                initial_value=first_database,
            ),
        ]
    )

    return chat_settings
