# Improvements

## Authentication

For local testing, you can bypass OAuth and use simple username/password authentication instead. Please refer to [here](https://docs.chainlit.io/authentication/password) for setting up password-based authentication for Sense and [here](https://docs.adminjs.co/installation/plugins/fastify) for Sense Admin.

## Images

We need to set up Sense and Sense Admin separately because they use different libraries that lack integration APIs. Ideally, both services would be built from scratch with Sense Admin integrated directly into Sense.

## Sense

For this Proof-of-Concept, we chose Chainlit for its chat interface and built-in APIs that integrate with LLM providers.
As an alternative, we could develop a custom chat interface using React and implement LLM providers integration with FastAPI.

## Sense Admin

For rapid development, we chose AdminJS, a JavaScript admin dashboard library that requires a one-off paid license for premium features like [relations](https://docs.adminjs.co/basics/features/relations). We used this with [Prisma](https://docs.adminjs.co/installation/adapters/prisma) and [Zenstack](https://zenstack.dev/docs/welcome) to implement the Organization-Team-Member relationship and database metadata management.
Alternatively, we could create a CRUD application to manage database records, user privileges and relationship between models.