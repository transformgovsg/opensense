# Running Locally with Docker Compose
>[!NOTE]
> Please go through [DEVELOPMENT.md](../DEVELOPMENT.md) first.

Docker and Docker Compose configurations have simplified running Sense locally. All required services are now consolidated in the [sense-full-suite-docker-compose.yml](../../sense-full-suite-docker-compose.yml) file.


## Requirements

- Docker
- Docker Compose
- OpenAI API Key
- AWS Cognito

## Setup AWS Cognito for OAuth

AWS Cognito provides authentication for both Sense and Sense Admin. Though other OAuth providers might work, AWS Cognito is the only thoroughly tested option. For setup instructions of AWS Cognito, refer to this [tutorial](https://www.freecodecamp.org/news/how-to-use-aws-cognito-for-user-authentication/).

You'll need the following values for both Sense and Sense Admin (if you are using AWS Cognito). For other OAuth providers. please refer [here](https://docs.chainlit.io/authentication/oauth) for Sense and [here](https://docs.adminjs.co/installation/plugins/fastify) for Sense Admin.

```bash
// AWS cognito example

// Sense
OAUTH_COGNITO_CLIENT_ID=some_random_hash_provided_by_provider
OAUTH_COGNITO_CLIENT_SECRET=some_random_secret_provided_by_provider
OAUTH_COGNITO_DOMAIN=random_hash.auth.ap-southeast-1.amazoncognito.com

// Sense Admin
OAUTH2_CLIENT_ID=some_random_hash_provided_by_provider
OAUTH2_CLIENT_SECRET=some_random_secret_provided_by_provider
OAUTH2_AUTH_URL=https://random_account.auth.ap-southeast-1.amazoncognito.com/oauth2/authorize
OAUTH2_TOKEN_URL=https://random_account.auth.ap-southeast-1.amazoncognito.com/oauth2/token
OAUTH2_LOGOUT_URL=https://random_account.auth.ap-southeast-1.amazoncognito.com/logout
OAUTH2_CALLBACK_URL=http://localhost:1234/auth/oauth/aws-cognito/callback
OAUTH2_LOGOUT_CALLBACK_URL=http://localhost:1234/auth/oauth/aws-cognito/logout
OAUTH2_JWKS_URL=https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_hL8Y1wWoo/.well-known/jwks.json
```

## Prep all .env configs

Each service requires its own .env configuration file. If a service uses an `env_file`, you must provide specific custom values for it to work.

Each service has a corresponding .env.xxx.example template file. Review these templates and fill in the required configuration values.

After cloning the [Sense](https://github.com/transformgovsg/opensense) and [Sense Admin](https://github.com/transformgovsg/opensense-admin) repositories, use the .env.xxx.example files as references to set up your configurations.

### Sense

Reference [.env.example](../../.env.example)

```bash
cp .env.example .env
```

### Sense Admin

Reference [.env.admin.example](../../.env.admin.example)

```bash
cp .env.admin.example .env.admin
```

### Langfuse

Reference [.env.admin.example](../../.env.admin.example) for basic setup. For advanced configuration options, refer to the [Langfuse doc](https://langfuse.com/self-hosting/configuration).

```bash
cp .env.langfuse.example .env.langfuse
```

## Build Images

Next, we will build the image for Sense.

### Sense

```bash
docker compose -f sense-full-suite-docker-compose.yml build sense
```

### Sense Admin

Visit [Sense Admin](https://github.com/transformgovsg/opensense-admin) and refer to the "Setting Up" section for instructions on the setup.

## Services Setup & Boot Order

1. sense_db
2. sense_cache
3. langfuse
4. metabase
5. sense_admin
6. sense

### 1. sense_db

`sense_db` is a PostgreSQL database that serves as the core database for all services. On startup, it creates all necessary databases and tables required by the services.

To learn more about the database structure, you can check the initialisation SQL scripts in the [scripts/full_suite_sql_inits](../../scripts/full_suite_sql_inits) directory.

```bash
docker compose -f sense-full-suite-docker-compose.yml up sense_db
```

### 2. sense_cache

`sense_cache` is a Redis cache mainly to serve for Sense Admin, nothing more really.

```bash
docker compose -f sense-full-suite-docker-compose.yml up sense_cache
```

### 3. langfuse

`langfuse` traces chat sessions and manages prompts. Upon startup, it creates an admin user and a project called 'Sense'.

> [!NOTE]
> Remember to generate and add NEXTAUTH_SECRET and SALT to [.env.langfuse](../../.env.langfuse). Please refer to [.env.langfuse.example](../../.env.langfuse.example) for more instructions. 

```bash
docker compose -f sense-full-suite-docker-compose.yml up langfuse
```

Once Langfuse is running, access it at http://localhost:1235. You'll need to create your first system prompt that Sense will use. For guidance on creating your first prompt, see the [Langfuse docs](https://langfuse.com/docs/prompts/get-started#createupdate-prompt).

>[!NOTE]
> Please refer to [.env.langfuse](../../.env.langfuse) for initial email and password login credentials.

Create a prompt named `metabase-guided-agent-chat` using the system prompt from [docs/prompts/chat_prompt_v2.txt](../prompts/chat_prompt_v2.txt). After creating it, save and promote the prompt to production.

### 4. metabase

`metabase` is a BI tool that Sense uses as a middleman to manage different data sources and execute read queries based on your prompts.

```bash
docker compose -f sense-full-suite-docker-compose.yml up metabase
```

After the service starts successfully, run the initialisation script to set up your first Metabase admin user and create an API key—both of which are required for Sense and Sense Admin.

```bash
./scripts/init_metabase.sh
```

### 5. sense_admin

`sense_admin` provides user management capabilities for Sense and Metabase.

```bash
docker compose -f sense-full-suite-docker-compose.yml up sense_admin
```

After initialisation, you'll need to access the container and run the following commands

```bash
npx prisma migrate deploy
npx prisma db seed -- --email '<your_email>@tech.gov.sg'
npx zenstack generate
```

### 6. sense

After building Sense with the appropriate .env configurations, you should be able to start the services without any problems.

```bash
docker compose -f sense-full-suite-docker-compose.yml up sense
```
🎉 Congrats! You are now done!

## Services Endpoints
You can access all the services via the following if you stick to the default ports config:
- Sense - [localhost:8051](http://localhost:8051)
- Sense Admin - [localhost:1234/admin](http://localhost:1234/admin)
- Metabase - [localhost:3000](http://localhost:3000)
- Langfuse - [localhost:1235/admin](http://localhost:1235)