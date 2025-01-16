import datetime
from io import StringIO

import chainlit as cl
import pandas as pd


def get_downloadable_file(df: pd.DataFrame) -> cl.File:
    buffer = StringIO()
    df.to_csv(buffer, index=False)

    return cl.File(
        name=f"dataco-{datetime.datetime.utcnow()}.csv",
        content=buffer.getvalue().encode(),
        display="inline",
        mime="text/csv",
    )
