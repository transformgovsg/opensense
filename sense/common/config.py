from email.policy import default
from typing import Literal, Optional

from pydantic import Field, HttpUrl, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

from sense.common.llm import LanguageModelType

DEPLOYMENT_MODE_TYPE = Literal["development"] | Literal["production"]


class Settings(BaseSettings):
    model_config = SettingsConfigDict()

    chainlit_auth_secret: SecretStr = Field()
    environment: str = Field()

    # Authentication
    oauth_cognito_client_id: Optional[str] = Field(default=None)
    oauth_cognito_client_secret: Optional[SecretStr] = Field(default=None)
    oauth_cognito_domain: Optional[str] = Field(default=None)

    # Application Configuration
    chainlit_url: Optional[HttpUrl] = Field(default=None)
    deployment_mode: DEPLOYMENT_MODE_TYPE = Field(default="development")

    # Langfuse Configuration
    langfuse_host: HttpUrl = Field()
    langfuse_public_key: SecretStr = Field()
    langfuse_secret_key: SecretStr = Field()

    # Metabase Configuration
    metabase_url: HttpUrl = Field()
    metabase_api_key: str = Field()
    metabase_http_timeout: Optional[int] = Field(default=60)

    # OpenAI API Configuration
    openai_api_base: Optional[HttpUrl] = Field()
    openai_api_key: SecretStr = Field()
    default_llm: Optional[LanguageModelType] = Field(default='gpt-4o')

    # Database Settings
    lit_database_url: Optional[SecretStr] = Field(default=None)

    # S3 Bucket for Storing Results
    result_storage_bucket_name: Optional[str] = Field(default=None)

    # Feature Flags
    guardrail_enabled: Optional[bool] = Field(default=False)
    db_whitelist_enabled: Optional[bool] = Field(default=True)
    rate_limit_enabled: Optional[bool] = Field(default=True)
    rate_limit_count: Optional[int] = Field(default=5)
    rate_limit_interval: Optional[int] = Field(default=300)
    db_whitelist_provider: Optional[str] = Field(
        default="CognitoAuthorizationProvider"
    )
    show_field_desc_to_human_enabled: Optional[bool] = Field(default=True)

    # Sense Admin
    sense_admin_base_url: Optional[str] = Field(default=None)
    sense_admin_api_key: Optional[str] = Field(default=None)


settings = Settings()  # type: ignore

assert settings.openai_api_base is not None

__all__ = ["settings"]
