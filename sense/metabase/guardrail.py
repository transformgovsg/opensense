import chainlit as cl
import httpcore
import httpx
from langchain_core.language_models import BaseChatModel
from langchain_core.messages import AIMessage
from langchain_core.prompts import (
    ChatPromptTemplate,
    SystemMessagePromptTemplate,
    HumanMessagePromptTemplate,
)
from retry_async import retry

from sense.common.llm import get_llm
from sense.common.monitoring import langfuse_client

GUARDRAIL_LLM_MODEL_NAME = "gpt-4o"


def pre_guardrail(chat_llm: BaseChatModel):
    pre_guardrail_prompt = ChatPromptTemplate.from_messages(
        [
            SystemMessagePromptTemplate.from_template(
                "You are a helpful assistant."
            ),
            HumanMessagePromptTemplate.from_template(
                langfuse_client.get_prompt(
                    "pre-guardrails"
                ).get_langchain_prompt()
            ),
        ]
    )
    return pre_guardrail_prompt | chat_llm


@retry(
    tries=3,
    delay=0.5,
    backoff=1,
    is_async=True,
    exceptions=(httpx.RemoteProtocolError, httpcore.RemoteProtocolError),
)
@cl.step(name="Screen message")
async def run_guardrails(message: cl.Message) -> bool:

    # These to functions are decoy functions to force the llm to make
    # decision.

    def mark_as_data_question():
        """
        This question is about data analysis or data query or data extraction.
        """

    def mark_as_non_data_question():
        """
        This question is about data analysis or data query or data extraction.
        """

    tools = [mark_as_data_question, mark_as_non_data_question]

    llm = get_llm(model=GUARDRAIL_LLM_MODEL_NAME).bind_tools(tools)
    pre_guardrail_chain = pre_guardrail(llm)
    result: AIMessage = await pre_guardrail_chain.ainvoke(
        {"message": message.content}
    )

    invoked_tools = map(lambda tool_call: tool_call["name"], result.tool_calls)
    return mark_as_data_question.__name__ in invoked_tools
