# app/Dockerfile
ARG REPO_URL
FROM ${REPO_URL}python:3.11-slim AS builder

RUN pip install poetry

ENV PYTHONUNBUFFERED=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

WORKDIR /app

COPY poetry.lock .
COPY pyproject.toml .
COPY README.md .

RUN pip install -U pip

RUN --mount=type=cache,target=$POETRY_CACHE_DIR poetry install --without dev --no-root


FROM ${REPO_URL}python:3.11-slim AS runtime

WORKDIR /app

ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

RUN apt-get update && apt-get install -y libpq-dev cron

COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

COPY launch.sh launch.sh
COPY scripts/purge_csv.sh purge_csv.sh
COPY sense sense
COPY .chainlit .chainlit
COPY public public
COPY chainlit.md chainlit.md

# Set up cron job
RUN echo "* * * * * /bin/bash /app/purge_csv.sh" > /etc/cron.d/purge-csv-cron
RUN chmod 0644 /etc/cron.d/purge-csv-cron
RUN crontab /etc/cron.d/purge-csv-cron

EXPOSE 8051

# Start cron service and then run the main entrypoint
ENTRYPOINT ["bash", "-c", "cron && bash launch.sh"]
