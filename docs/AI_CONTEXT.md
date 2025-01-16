# Sense: Comprehensive Context Documentation

## Overview

Sense is an innovative application that enables users to interact with SQL databases through natural language conversations. By leveraging large language models (LLMs), Sense translates English questions into SQL queries, allowing users to access and manipulate database information without requiring expertise in SQL.

## Key Features

- **Natural Language Processing**: Users can ask questions in English, which are converted into SQL queries by the LLM.
- **Database Introspection and Query Execution**: Utilizes the Metabase API to introspect database schemas and execute queries.
- **Chat History Management**: Stores conversations in a PostgreSQL database for context preservation and future reference.
- **Versioned Prompt Management**: Connects to Langfuse for hosting and versioning prompts and prompt templates used by the LLM.
- **Dual Agent System**: You can switch between agents using the UI.
  - **Autonomous Agent**: Implements an autonomous agent capable of handling complex queries and multi-step reasoning.
  - **Conversational Agent**: Provides a more interactive, dialogue-based approach for query refinement and user assistance.
- **Data Visualization**: Provides data preview and visualization capabilities for query results.
- **Error Handling**: Implements robust error handling and sanitization for LLM-generated queries.
- **Security**: Implements database whitelisting and query guardrails to ensure secure operations.

## Technical Architecture

### Frontend and Backend Framework

- **Chainlit**: A Python-based chatbot UI framework used to build the interface.
    - **Frontend**: Built with React for a responsive user experience.
    - **Backend**: Powered by FastAPI, a fast and modern web framework for building APIs with Python.
    - **Communication**: Utilizes WebSockets for real-time communication between the frontend and backend.

### Language Model Integration

- **LangChain**: A Python library employed for LLM-related functionalities.
    - **Agent Creation**: Constructs a LangChain agent that responds to user messages.
    - **Tool Execution**: The agent is equipped with a set of tools that the LLM can execute as needed.
    - **Iterative Processing**: Operates in a finite loop, processing responses until an answer is derived or a timeout occurs.

### Core Components

1. **Configuration Management** (`sense/common/config.py`):
   - Manages application settings using the `Settings` class.
   - Handles environment variables and default configurations.

2. **LLM Integration** (`sense/common/llm.py`):
   - Provides the `get_llm` function to initialize and configure the language model.
   - Supports different LLM providers and configurations.

3. **Agent System**:
   a. **Autonomous Agent** (`sense/metabase/agent_autonomous.py`):
      - Implements the `invoke_agent_with_msg` function for handling complex queries with retry logic.
      - Utilizes decorators for retry mechanisms on network errors.
   b. **Conversational Agent** (`sense/metabase/agent_conversational.py`):
      - Implements a dialogue-based approach for query refinement and user interaction.
      - Handles multi-turn conversations to clarify user intent and provide more accurate results.

4. **Error Handling** (`sense/metabase/exceptions.py`):
   - Defines custom exceptions like `InvalidQueryGenerated` and `LLMGoofed`.
   - Provides error sanitization functions to clean sensitive information from error messages.

5. **Query Guardrails** (`sense/metabase/guardrail.py`):
   - Implements pre-execution guardrails to validate and secure LLM-generated queries.
   - Uses the `pre_guardrail` function to check queries before execution.

6. **Metabase API Integration** (`sense/metabase/metabase_api.py`):
   - Provides a comprehensive set of asynchronous functions to interact with the Metabase API, including:
     - Database and dataset listing
     - Question creation, updating, and deletion
     - Query execution and result fetching
     - Card metadata retrieval
     - Enum value discovery

7. **LLM Tools** (`sense/metabase/tools.py`):
   - Defines a set of tools for the LLM agent to use, including:
     - Dataset listing
     - Question creation and updating
     - Database whitelisting checks
     - Enum value addition to fields
   - Utilizes decorators for tool definition and input validation.

8. **UI Data Handling** (`sense/metabase/ui/data.py`):
   - Manages data preview and visualization, including:
     - Sending data previews
     - Preparing data preview messages
     - Generating downloadable files from dataframes
     - Providing random in-progress messages for user feedback

### Additional Components

- **Public Assets** (`public/`):
  - Contains JavaScript and CSS files for frontend enhancements, including:
    - GovSG banner integration
    - Page height adjustment for the masthead

- **Changelog Generation** (`scripts/changelogs.py`):
  - Provides utilities for generating and updating changelogs based on git logs.
  - Includes functions to generate friendly changelogs and replace existing changelog content.

## Workflow

1. **User Interaction**: A user inputs a question in English via the Chainlit interface.
2. **Agent Selection**: The system determines whether to use the Autonomous Agent or the Conversational Agent based on the query complexity and user interaction history.
3. **Schema and Question Processing**: The application's Metabase API introspects the database schema.
4. **LLM Query Generation**:
    - The user's question and the database schema are sent to the LLM.
    - The LLM, via the selected LangChain agent, generates the corresponding SQL query.
5. **Tool Utilization**:
    - If necessary, the LLM selects and executes tools provided by the agent to refine the query.
6. **Query Validation**: The generated SQL query passes through guardrails for security checks.
7. **Query Execution**: The validated SQL query is executed against the whitelisted database.
8. **Response Delivery**: Results are sent back to the user through the Chainlit interface, with data previews and visualization options.
9. **Conversation Management**: 
    - For the Autonomous Agent: The interaction is stored for context preservation.
    - For the Conversational Agent: The system engages in a multi-turn dialogue if needed, clarifying user intent and refining the query.
10. **Conversation Storage**: The entire interaction is stored in a PostgreSQL database for history tracking.

## Integration with Langfuse

- **Prompt Management**: Sense connects to Langfuse to manage and version control the prompts and templates used by the LLM.
- **Consistency and Updates**: Langfuse ensures that the prompts are consistent across different sessions and allows for seamless updates.
- **Performance Tracking**: Potentially used for monitoring LLM performance and prompt effectiveness.

## Security Measures

- **Database Whitelisting**: Implements checks to ensure queries are only executed against approved databases.
- **Query Guardrails**: Pre-execution checks to validate and secure LLM-generated queries.
- **Error Message Sanitization**: Removes sensitive information from error messages before displaying to users.
- **Asynchronous Operations**: Utilizes async functions to handle concurrent requests efficiently and securely.

## Benefits

- **User-Friendly Interface**: Enables users without SQL knowledge to interact with databases efficiently.
- **Real-Time Communication**: WebSocket integration ensures smooth and instant feedback.
- **Modular Architecture**: The use of Chainlit, LangChain, and Langfuse allows for flexibility and scalability.
- **Enhanced Productivity**: Automates complex query generation, saving time and reducing errors.
- **Robust Error Handling**: Implements safeguards against invalid queries and provides meaningful error messages.
- **Data Visualization**: Offers immediate data previews and downloadable results for further analysis.
- **Extensible Tool Set**: The modular tool design allows for easy addition of new capabilities to the LLM agent.
- **Security-Focused**: Implements multiple layers of security to protect data and prevent unauthorized access.

## Development Guidelines

When working on the Sense project, developers should:

1. Adhere to the existing code structure and naming conventions.
2. Utilize the provided error handling mechanisms and guardrails when implementing new features.
3. Extend the tool set in `sense/metabase/tools.py` when adding new capabilities to the LLM agent.
4. Update the Metabase API functions in `sense/metabase/metabase_api.py` when introducing new database interactions.
5. Implement proper error handling and input validation for all new functions and API endpoints.
6. Use the configuration management system in `sense/common/config.py` for any new configurable parameters.
7. Ensure all database interactions are subject to whitelisting checks.
8. Write asynchronous code where appropriate, especially for I/O-bound operations.
9. Update this context documentation when making significant changes to the project structure or introducing new major features.
10. Regularly review and update security measures, including guardrails and error sanitization.
