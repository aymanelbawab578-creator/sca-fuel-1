from pathlib import Path
import re

src = Path(r"c:\Users\FIRST\Desktop\sca\backup_neon_before_supabase.sql")
out = Path(r"c:\Users\FIRST\Desktop\sca\backup_neon_before_supabase_insert_ready.sql")

text = src.read_text(encoding="utf-8")
lines = text.splitlines()

result = []
section_count = 0
row_count = 0

def format_value(val: str):
    v = val.strip()
    if v == r"\\N":
        return "NULL"
    if v.lower() == "t":
        return "true"
    if v.lower() == "f":
        return "false"
    if v == "":
        return "''"
    if re.fullmatch(r"-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?", v):
        return v
    return "'" + v.replace("'", "''") + "'"


i = 0
while i < len(lines):
    line = lines[i]
    if line.startswith("COPY "):
        m = re.match(r'^COPY\s+(.+?)\s*\((.*?)\)\s+FROM\s+stdin;$', line)
        if m:
            table = m.group(1).strip()
            cols = [c.strip() for c in m.group(2).split(',') if c.strip()]
            section_count += 1
            data_lines = []
            i += 1
            while i < len(lines) and lines[i] != r"\\.":
                data_lines.append(lines[i])
                i += 1
            if i < len(lines) and lines[i] == r"\\.":
                for row in data_lines:
                    if not row.strip():
                        continue
                    values = row.split("\t")
                    if len(values) < len(cols):
                        values = values + [""] * (len(cols) - len(values))
                    elif len(values) > len(cols):
                        values = values[:len(cols)]
                    row_count += 1
                    result.append(
                        f"INSERT INTO {table} ({', '.join(cols)}) VALUES ({', '.join(format_value(v) for v in values)});"
                    )
                i += 1
                continue
        result.append(line)
        i += 1
        continue
    result.append(line)
    i += 1

out.write_text("\n".join(result) + "\n", encoding="utf-8")
print(f"Converted sections: {section_count}")
print(f"Inserted rows: {row_count}")
print(f"Wrote: {out}")
