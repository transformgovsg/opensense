. as $db | {
  tables: [.tables[] |
    {
      engine: (($db.dbms_version | .flavor // empty) // $db.engine),
      description: (if .description then .description | gsub("\n"; " ") else null end),
      table_name: (.schema + "." + .name),
      fields: [.fields[]
        | {
          database_type,
          name,
          display_name,
          description: (if .description then .description | gsub("\n"; " ") else null end),
          slugified_display_name: (.display_name | ascii_downcase | gsub(" "; "_") | gsub("[^a-z0-9_]"; "")),
          enums: (if .enums then .enums else [] end)
        }
      ]
    }
  ]
}
| del(.. | nulls)
| .tables[]
| "CREATE TABLE \(.table_name) ( -- Database Engine: \(.engine)\n" +
  (
    if .description then "-- " + (.table_name) + " Table Description: \(.description)\n" else "" end
  ) +
  ([
    .fields[]
    | "  \(.name) \(.database_type)," +
      (if .description != null or .slugified_display_name != .name or (.enums | length) > 0 then " -- " else "" end) +
      (if .description then .description else "" end) +
      (if .slugified_display_name != .name and .description == null then .display_name else "" end) +
      (if (.enums | length) > 0 then "Possible Values: \"" + (.enums | join("\", \"")) + "\"" else "" end )
  ] | join("\n")) +
  "\n); -- Database Engine: \(.engine)\n"