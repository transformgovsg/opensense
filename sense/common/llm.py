from typing import Literal

from langchain_openai.chat_models import ChatOpenAI

LANGUAGE_MODELS = ["gpt-3.5-turbo", "gpt-4-1106-preview", "gpt-4o"]
LanguageModelType = Literal["gpt-3.5-turbo", "gpt-4-1106-preview", "gpt-4o"]


def get_llm(**kwargs):
    return ChatOpenAI(temperature=0, streaming=True, **kwargs)


__all__ = ["LANGUAGE_MODELS", "LanguageModelType", "get_llm"]
