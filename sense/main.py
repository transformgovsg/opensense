import os
import string
import logging
import sys

import chainlit.secret  # noqa: E402
import chainlit.socket  # noqa: E402
from chainlit.cli import run_chainlit  # noqa: E402
from chainlit.config import config  # noqa: E402

# Override Chainlit's logging configuration (mostly)
# This will override the handler configuration (base log level, formatting)
# This will not override individual logger's log levels (such as socketio, as defined by Chainlit)
# Set the base log level here, then override for specific logger later
for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)

logging.basicConfig(
    level=logging.INFO,
    stream=sys.stdout,
    format='%(asctime)s %(levelname)s %(name)s %(message)s',
    datefmt="%Y-%m-%d %H:%M:%S",
)

# Example of overriding log level for a logger
# openai will give you request-response at DEBUG. Extremely useful, but will contain sensitive data
# logging.getLogger("openai").setLevel(logging.DEBUG)

if os.environ.get("DEPLOYMENT_MODE") == "production":
    config.run.headless = True

# We have to do this because, `^+` in the OAuth /authorize step
# trips up AWS Cognito. So we are monkey-patching out this
# character.it
# FIXME: Remove this monkeypatch once chainlit fixes it
chainlit.secret.chars = string.ascii_letters + string.digits

run_chainlit("sense/metabase/server.py")
