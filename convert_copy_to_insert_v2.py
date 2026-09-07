from pathlib import Path
import re

path = Path(r"c:\Users\FIRST\Desktop\sca\backup_neon_before_supabase.sql")
backup_path = path.with_suffix(path.suffix + ".bak")
if not backup_path.exists():
    backup_path.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

text = path.read_text(encoding="utf-8")

pattern = re.compile(r"COPY\s+([^\s]+)\s*\((.*?)\)\s+FROM\s+stdin;\n(.*?)\n\\.", re.S)


def fmt(val: str):
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


def repl(match):
    table = match.group(1).strip()
    columns = [c.strip() for c in match.group(2).split(",") if c.strip()]
    rows = []
    block = match.group(3)
    for raw_row in block.splitlines():
        if not raw_row.strip():
            continue
        values = raw_row.split("\t")
        if len(values) < len(columns):
            values += [""] * (len(columns) - len(values))
        elif len(values) > len(columns):
            values = values[:len(columns)]
        rows.append("INSERT INTO " + table + " (" + ", ".join(columns) + ") VALUES (" + ", ".join(fmt(v) for v in values) + ");")
    return "\n".join(rows)

new_text = pattern.sub(repl, text)
path.write_text(new_text, encoding="utf-8")
print(f"Updated {path}")
print(f"Backup {backup_path}")
