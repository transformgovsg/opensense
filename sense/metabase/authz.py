import abc
import json
from typing import TypedDict

import chainlit as cl
import httpx

from sense.common.config import settings

import logging
logger = logging.getLogger(__name__)

class AuthCallback(TypedDict):
    provider_id: str
    token: str
    raw_user_data: dict[str, str]
    default_user: cl.User


from typing import TypedDict


class AccessRight(TypedDict):
    dataSourceId: int


class SenseAdminUser(TypedDict):
    id: str
    remoteId: str
    email: str
    accessRights: list[AccessRight]


class BaseAuthorizationProvider(metaclass=abc.ABCMeta):
    @abc.abstractmethod
    async def get_whitelisted_db_ids(
        self, callback: AuthCallback
    ) -> list[int]:
        raise NotImplementedError


class CognitoAuthorizationProvider(BaseAuthorizationProvider):
    async def get_whitelisted_db_ids(
        self, callback: AuthCallback
    ) -> list[int]:
        custom_whitelisted_db = callback["raw_user_data"].get(
            "custom:whitelisted_db", "{}"
        )
        db_ids = json.loads(custom_whitelisted_db).get(
            settings.environment, []
        )
        return db_ids


class SenseAdminAuthorizationProvider(BaseAuthorizationProvider):
    client: httpx.AsyncClient

    def __init__(self):
        if (
            not settings.sense_admin_base_url
            or not settings.sense_admin_api_key
        ):
            raise EnvironmentError(
                "SenseAdminAuthorizationProvider enabled but, "
                "SENSE_ADMIN_BASE_URL or SENSE_ADMIN_API_KEY not configured"
            )

        self.client = httpx.AsyncClient(
            base_url=settings.sense_admin_base_url,
            headers={
                "x-api-key": settings.sense_admin_api_key,
            },
        )

    async def get_whitelisted_db_ids(
        self, callback: AuthCallback
    ) -> list[int]:
        cl_user = callback["default_user"]
        response = await self.client.get(f"/api/v1/users/{cl_user.identifier}")
        data: SenseAdminUser = response.json()

        logger.info('Sense Admin User: %s Response: %s', cl_user, data)
        return [d["dataSourceId"] for d in data["accessRights"]]
