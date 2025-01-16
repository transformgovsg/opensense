from pathlib import Path

PUBLIC_DIR = Path(__file__).parent.parent.parent / "public"
MISC_DIR = Path(__file__).parent / "misc"

with open(MISC_DIR / "format_metabase_metadata.jq") as jq_file:
    METABASE_METADATA_QUERY = jq_file.read()

with open(MISC_DIR / "format_user_metadata.jq") as jq_file:
    FORMAT_USER_METADATA_QUERY = jq_file.read()

with open(MISC_DIR / "format_user_metadata_with_desc.jq") as jq_file:
    FORMAT_USER_METADATA_DESC_QUERY = jq_file.read()

_CSP_HASH_COLOR_THEME_JS = (
    "sha256-jxQoCX05rLiV+7ZfFd5qhY1k+2Utq5zj6/si0TgZoYQ="
)

# Content-Security-Policy (CSP)
CSP = (
    f"""
default-src 'self';
script-src 'self'
    https://cdn.jsdelivr.net
    'sha256-ZWRmwzAxW0f296BzqIa7q7BIoyXzvRoPEDPK9GgizWM='
    'sha256-20j3WcL/cq9Bb1jvtRZ3Eo1NIAIovziWZTzuq2rpaa4='
    'sha256-cP/ZZjx7bZr9og1v1+9DviQFgmk0hlvIhQ3dXH0Nu6M='
    '{_CSP_HASH_COLOR_THEME_JS}';
style-src 'self'
    https://fonts.googleapis.com
    https://cdn.jsdelivr.net
    'sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU='
    'sha256-6FtdOVEKBr7kEvnxnYQJQC1ilZSJF49hIGiqrX5SLiA=';
font-src 'self'
    https://fonts.gstatic.com
    https://cdn.jsdelivr.net;
object-src 'none';
frame-ancestors 'none';
form-action 'self';
""".strip()
    .replace("\n", " ")
    .replace("\t", " ")
)

ONE_YEAR_IN_SECONDS = 31536000

MAX_ROWS_IN_CHAT_WINDOW = 20
MAX_ROWS_IN_DOWNLOAD_FILE = 2_000