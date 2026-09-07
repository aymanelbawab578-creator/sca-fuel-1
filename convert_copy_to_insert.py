from pathlib import Path
import re

path = Path(r"c:\Users\FIRST\Desktop\sca\backup_neon_before_supabase.sql")
backup_path = path.with_suffix(path.suffix + ".bak")
if not backup_path.exists():
    backup_path.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

text = path.read_text(encoding="utf-8")
lines = text.splitlines()
result = []
i = 0
while i < len(lines):
    line = lines[i]
    if line.startswith("COPY "):
        m = re.match(r'^COPY\s+(.+?)\s*\((.*)\)\s+FROM\s+stdin;$', line)
        if m:
            table = m.group(1).strip()
            columns = [c.strip() for c in m.group(2).split(',')]
            data_lines = []
            i += 1
            while i < len(lines) and lines[i] != r"\.":
                data_lines.append(lines[i])
                i += 1
            if i < len(lines) and lines[i] == r"\.":
                for row in data_lines:
                    if not row.strip():
                        continue
                    values = row.split("\t")
                    if len(values) < len(columns):
                        values = values + [""] * (len(columns) - len(values))
                    elif len(values) > len(columns):
                        values = values[:len(columns)]

                    formatted = []
                    for val in values:
                        val = val.strip()
                        if val == r"\\N":
                            formatted.append("NULL")
                        elif val.lower() == "t":
                            formatted.append("true")
                        elif val.lower() == "f":
                            formatted.append("false")
                        elif val == "":
                            formatted.append("''")
                        elif re.fullmatch(r"-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?", val):
                            formatted.append(val)
                        else:
                            formatted.append("'" + val.replace("'", "''") + "'")

                    result.append(
                        f"INSERT INTO {table} ({', '.join(columns)}) VALUES ({', '.join(formatted)});"
                    )
                i += 1
                continue
        result.append(line)
        i += 1
        continue

    result.append(line)
    i += 1

path.write_text("\n".join(result) + "\n", encoding="utf-8")
print(f"Updated {path}")
print(f"Backup at {backup_path}")
