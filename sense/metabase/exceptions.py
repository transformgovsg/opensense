import re


class PreGuardrailsFailed(Exception):
    pass


class LLMGoofed(Exception):
    pass


class InvalidQueryGenerated(LLMGoofed):
    pass


UUID_REGEXP = re.compile(
    r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
)


def sanitise_error_message(message: str) -> str:
    message = UUID_REGEXP.sub("", message)
    message = message.replace("[Simba]", "")

    return message
