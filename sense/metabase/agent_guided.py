from typing import Any

import chainlit as cl
import httpcore
import httpx
from langchain.agents import AgentExecutor, create_openai_tools_agent
from langchain.memory import ConversationBufferWindowMemory
from langchain.memory.chat_memory import BaseChatMemory
from langchain_core.prompts import (
    ChatPromptTemplate,
    HumanMessagePromptTemplate,
    MessagesPlaceholder
)
from langchain_core.runnables import RunnableConfig
from langchain_core.tools import BaseTool
from langfuse.callback.langchain import (
    LangchainCallbackHandler as LangfuseCallbackHandler,
)
from retry_async import retry

from sense.common.config import settings
from sense.common.llm import get_llm
from sense.common.monitoring import langfuse_client


def create_guided_agent(
        memory: BaseChatMemory,
        tools: list[BaseTool]
) -> AgentExecutor:
    prompt = ChatPromptTemplate.from_messages(
        messages=[
            *langfuse_client.get_prompt(
                "metabase-guided-agent-chat"
            ).get_langchain_prompt(),
            MessagesPlaceholder(optional=True, variable_name="chat_history"),
            HumanMessagePromptTemplate.from_template(
                "## Database Schema\n\n{database_schema}"
            ),
            HumanMessagePromptTemplate.from_template("## Question\n{input}"),
            MessagesPlaceholder(
                optional=False, variable_name="agent_scratchpad"
            ),
        ]
    )

    verbose_output = settings.deployment_mode != "production"

    agent = create_openai_tools_agent(
        llm=get_llm(model=settings.default_llm),
        tools=tools,  # type: ignore
        prompt=prompt
    )

    return AgentExecutor(
        agent=agent,  # type: ignore
        tools=tools,
        verbose=verbose_output,
        handle_parsing_errors=True,
        return_intermediate_steps=True,
        memory=memory,
    )


def get_memory(num_of_messages_in_memory: int):
    return ConversationBufferWindowMemory(
        memory_key="chat_history",
        input_key="input",
        output_key="output",
        return_messages=True,
        k=num_of_messages_in_memory,
    )


@retry(
    tries=3,
    delay=0.5,
    backoff=1,
    is_async=True,
    exceptions=(httpx.RemoteProtocolError, httpcore.RemoteProtocolError),
)
async def invoke_agent_with_msg(
        agent: AgentExecutor,
        input_data: dict[str, Any],
        user_id: str | None,
        session_id: str | None,
):
    intermediate_cb = cl.AsyncLangchainCallbackHandler(
        stream_final_answer=True, force_stream_final_answer=True
    )
    tracing_cb = LangfuseCallbackHandler(
        user_id=user_id, session_id=session_id
    )
    agent_config = RunnableConfig(callbacks=[intermediate_cb, tracing_cb])
    await agent.ainvoke(input=input_data, config=agent_config)
