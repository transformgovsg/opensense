(
  .tables | map(
    "### " + (.schema + "." + .name) + " (" + .display_name + ")" + "\n\n" +
    (
      if .description then
        "Description: " + (.description | gsub("\n"; " ")) + "\n\n"
      else
        ""
      end
    ) +
    "| Column Name | Display Name | Type | Description |\n" +
    "|-------------|--------------|------|-------------|\n" +
    (
      .fields | map(
        "| " + (.name // "") +
        " | " + (.display_name // "") +
        " | " + (.semantic_type // "" | gsub("type/"; " ")) +
        " | " + (
          if .description then
            (.description | gsub("\n"; " "))
          else
            ""
          end
        ) + " |"
      ) | join("\n")
    ) +
    "\n\n"
  ) | join("")
)
