(
  .tables | map(
    "### " + (.schema + "." + .name) + " (" + .display_name + ")" + "\n\n" +
    "| Column Name | Display Name | Type |\n" +
    "|-------------|--------------|----- |\n" +
    (
      .fields | map(
        "| " + (.name // "") +
        " | " + (.display_name // "") +
        " | " + (.semantic_type // "" | gsub("type/"; " ")) +
        " | "
      ) | join("\n")
    ) +
    "\n\n"
  ) | join("")
)
