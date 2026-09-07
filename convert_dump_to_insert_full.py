from pathlib import Path
import re

input_path = Path(r"c:\Users\FIRST\Desktop\sca\backup_neon_before_supabase.sql.bak")
output_path = Path(r"c:\Users\FIRST\Desktop\sca\backup_neon_before_supabase_insert_ready.sql")

text = input_path.read_text(encoding="utf-8")
lines = text.splitlines()

result = []
statement_count = 0

# regex for PostgreSQL COPY header
copy_re = re.compile(r'^COPY\s+(.+?)\s*\((.*?)\)\s+FROM\s+stdin;$')

idx = 0
while idx < len(lines):
    line = lines[idx]
    m = copy_re.match(line)
    if m:
        table = m.group(1).strip()
        columns = [c.strip() for c in m.group(2).split(',')]
        data_lines = []
        idx += 1
        while idx < len(lines) and lines[idx] != r"\.":
            data_lines.append(lines[idx])
            idx += 1
        if idx < len(lines) and lines[idx] == r"\.":
            # emit INSERTs for each row
            for row in data_lines:
                if not row.strip():
                    continue
                values = row.split("\t")
                if len(values) < len(columns):
                    values = values + [""] * (len(columns) - len(values))
                elif len(values) > len(columns):
                    values = values[:len(columns)]

                formatted = []
                for raw in values:
                    val = raw.strip()
                    if val == r"\N":
                        formatted.append("NULL")
                        continue
                    if val.lower() == "t":
                        formatted.append("true")
                        continue
                    if val.lower() == "f":
                        formatted.append("false")
                        continue
                    if val == "":
                        formatted.append("''")
                        continue

                    # Decode escaped unicode sequences such as \u0628\u0646\u0632\u064a\u0646.
                    if "\\u" in val:
                        try:
                            val = val.encode("utf-8").decode("unicode_escape")
                        except Exception:
                            pass

                    if re.fullmatch(r"-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?", val):
                        formatted.append(val)
                    else:
                        escaped = val.replace("'", "''")
                        formatted.append("'" + escaped + "'")

                result.append(
                    f"INSERT INTO {table} ({', '.join(columns)}) VALUES ({', '.join(formatted)});"
                )
                statement_count += 1
            idx += 1
            continue

    result.append(line)
    idx += 1

output_path.write_text("\n".join(result) + "\n", encoding="utf-8")
print(f"Wrote {statement_count} INSERT statements to {output_path}")
print(f"Remaining COPY occurrences: {sum(1 for line in output_path.read_text(encoding='utf-8').splitlines() if line.startswith('COPY '))}")
