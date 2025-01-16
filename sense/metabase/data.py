import re
from dataclasses import dataclass

import pandas as pd

from sense.metabase import metabase_api
from sense.metabase.consts import MAX_ROWS_IN_DOWNLOAD_FILE
from sense.metabase.exceptions import InvalidQueryGenerated

METABASE_INVALID_QUERY = re.compile("invalid[-_]query")


@dataclass
class DataPreview:
    df: pd.DataFrame
    sql_query: str
    card_id: int


async def get_data_preview(card_id: int, sql_query: str) -> DataPreview:
    card_response = await metabase_api.run_card_query_limit_rows(
        card_id, row_count=MAX_ROWS_IN_DOWNLOAD_FILE
    )

    error_message = card_response.get("error")
    error_type = card_response.get("error_type") or ''

    is_error = (
            error_message
            and METABASE_INVALID_QUERY.match(error_type)
    )

    if is_error:
        raise InvalidQueryGenerated(card_response["error"])

    rows = card_response.get("data", {}).get("rows", [])
    cols = card_response.get("data", {}).get("cols", [])

    if len(rows) == 0:
        return DataPreview(pd.DataFrame(), sql_query, card_id)

    df = pd.DataFrame(
        rows,
        columns=[col["name"] for col in cols],
    )

    # Round floats to 2 decimals and also add the commas
    float_cols = df.select_dtypes(include=['float']).columns
    df[float_cols] = df[float_cols].map(
        lambda x: f"{x:,.2f}" if pd.notnull(x) else x
    )

    # Format integers with commas
    int_cols = df.select_dtypes(include=['int']).columns
    df[int_cols] = df[int_cols].map(lambda x: f"{x:,}" if pd.notnull(x) else x)

    return DataPreview(df, sql_query, card_id)


