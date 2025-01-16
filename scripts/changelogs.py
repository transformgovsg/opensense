#!/usr/bin/env python3

import os
import re
import sys
from pathlib import Path

from openai import OpenAI

client = OpenAI(base_url=os.environ.get("OPENAI_API_BASE", default=None))


def generate_friendly_changelogs(git_logs: str):
    response = client.chat.completions.create(
        model="gpt-4-1106-preview",
        messages=[
            {
                "role": "system",
                "content": "Return a beautiful markdown list of changes that a user of this software would be pleased "
                "to know about; not necessarily things that developers only would care about.\n\n"
                "Example:\nThings devs care about: CI/CD, dependencies, refactors etc\n"
                "Things users care about: better UI, better performance, new features\n\n"
                "Write out the output as a markdown list, user friendly language. Concise. Minimise items."
                "If there is no changes, just say something like regular maintenance and minor updates.\n"
                "Do not write headings, just markdown list items.",
            },
            {"role": "user", "content": git_logs},
        ],
        temperature=1,
        max_tokens=256,
        top_p=1,
        frequency_penalty=0,
        presence_penalty=0,
    )

    return response.choices[0].message.content


def replace_changelog(filename: os.PathLike, new_content: str):
    # Read the original content from the file
    with open(filename, "r", encoding="utf-8") as file:
        content = file.read()

    pattern = (
        r"(\[//\]: # \(CHANGELOG_START\)).*?(\[//\]: # \(CHANGELOG_END\))"
    )

    updated_content = re.sub(
        pattern, f"\\1\n\n{new_content}\n\n\\2", content, flags=re.DOTALL
    )

    with open(filename, "w", encoding="utf-8") as file:
        file.write(updated_content)


if __name__ == "__main__":
    git_logs = sys.stdin.read().strip()

    if not git_logs:
        print("No changes detected for changelog generation")
        exit()

    replace_changelog(
        filename=Path(__file__).parent.parent.joinpath("chainlit.md"),
        new_content=generate_friendly_changelogs(git_logs),
    )
