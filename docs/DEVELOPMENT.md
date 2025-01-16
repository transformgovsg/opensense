# Development Setup

## Requirements

- Python `^3.11`
- Poetry ([Installation](https://python-poetry.org/docs/#installation))
- Node `v18.16.1`

## MacOS ARM Requirements

For arm-based Macs, there seems to be requirements to have `greenlet` installed else you see a bunch of error messages appearing in your logs.

```bash
pip install greenlet
```

## Local Setup

### Clone the project

```bash
git clone git@github.com:transformgovsg/sense.git
```

### Setup Project Linters & Hooks

We use modern npm libraries to help with linting of this entire project.

```bash
npm install
```

### Install Project Dependencies w/ Poetry

```bash
poetry install
```

### Enter Poetry Shell

```bash
poetry shell
```

### Setup .env file with necessary values

```bash
cp .env.example .env
```

Take a look at the example, and fill in necessary information. This involves information from the respective services as referenced in [Getting Started](https://www.notion.so/Sense-160c63f3a34a80609c54d28782299b4e?pvs=21).

### Launch the app

In order for the app to work successfully, make sure you have the respective services up and running first as referenced in [Running Locally with Docker Compose](./local/LOCAL_SETUP.md) or hosted in the cloud.

```bash
python -m sense.main
```

## e2e Test(s)

At this moment, we only have e2e tests that are written in playwright.

### Set the following environment variables in .env file

```bash
# tweak this accordingly to your environment
SENSE_BASE_URL=http://localhost:8051

# create a test user
E2E_USERNAME=
E2E_PASSWORD=
```

### Run the tests

```bash
npx playwright test
```

To run in browser mode

```bash
npx playwright test --headed
```

To run in ui mode which is helpful for debugging

```bash
npx playwright test --ui
```

For more options, do check out playwright [docs](https://playwright.dev/docs/intro).