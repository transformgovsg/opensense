# Code Flow Documentation

## Application Entry Point and Main File

The entry point to the application is `main.py`, and the main file of the application is `server.py`.

## Chainlit and Socket.io

Chainlit operates on Socket.io, so rather than HTTP requests, there are a bunch of events that Chainlit listens to. When the user sends a message in chat, the event is `on_message()`.

## Agent Architecture

We use AgentExecutor from Langchain to construct our agent. The agent follows this convention:

1. Prompt (retrieved from Langfuse)
2. Placeholder for chat history
3. Placeholder for database schema
4. Placeholder for question
5. Scratchpad

### AgentExecutor and Deprecation

AgentExecutor is the traditional way of creating agents in Langchain. However, it's important to note that AgentExecutor is now considered deprecated. The recommended replacement is CreateReactAgent, which offers improved functionality and better integration with newer Langchain features.

### Agent Tools

Our agent is equipped with two primary tools:

1. ListDatasetsHumanFriendlyShowToUserTool
   - This tool is responsible for presenting a user-friendly list of available datasets to the user.
   - It helps users understand what data is available for querying.
   - The tool works as follows:
     a. It first checks if the user has access to the requested Database ID using the `check_db_whitelisted` method.
     b. If the user has access, it calls the Metabase API to list datasets for the given database ID.
     c. The retrieved dataset information is then formatted into a user-friendly representation.
     d. Finally, the formatted dataset information is sent directly to the user via a `cl.Message`.

2. CreateMetabaseQuestionTool
   - This tool allows the agent to create and execute Metabase questions based on user queries.
   - It interfaces with the Metabase API to run SQL queries and retrieve results.
   - The tool operates as follows:
     a. Check if the user is within rate limits.
     b. Verify that the user has access to the requested database.
     c. Parse the SQL query, uppercasing keywords and re-indenting the statement.
     d. Create a Metabase question using the parsed SQL query.
     e. If the question is successfully created:
        - Get a data preview from the Metabase question.
        - Execute the `on_preview_done` callback (which is the `render_data_preview` function in server.py).
     f. In case of an error:
        - Delete the created question.
        - Raise an exception with details about the error.

## Detailed Code Flow

1. **Message Handling (`on_message()`):**
   - Checks if the user has access to the selected database
   - If no access, terminates with an error message
   - Runs the message through guardrails
   - If guardrails flag the message as irrelevant, terminates with an error message
   - Otherwise, invokes the agent using `_invoke_agent()`

2. **Agent Invocation (`_invoke_agent()`):**
   - Retrieves the agent from the session object
   - Uses `ListDatasetsTool` to get the database schema for the agent
   - Passes the schema to the agent
   - Invokes the agent with the user's message and database schema

3. **Agent Setup (`setup_agent()`):**
   - Triggered via `on_settings_update` when the user changes the selected database
   - Creates fresh memory for the agent
   - Sets up tools for the agent, including the selected database ID
   - Creates a guided agent with the new memory and tools

4. **Database Selection:**
   - When a new database is selected, it triggers `on_settings_update`
   - This in turn calls `setup_agent()`, creating a new agent instance
   - The selected database ID is incorporated into the Langchain tools

5. **Tool Configuration:**
   - The selected database ID and user information are baked into the Langchain tools
   - This ensures that each tool operates within the context of the selected database and user permissions

