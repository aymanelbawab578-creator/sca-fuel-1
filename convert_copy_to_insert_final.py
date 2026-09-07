from pathlib import Path
import re

path = Path(r"c:\Users\FIRST\Desktop\sca\backup_neon_before_supabase.sql")
text = path.read_text(encoding="utf-8")

pattern = re.compile(r"COPY\s+(.+?)\s*\((.*?)\)\s+FROM\s+stdin;\n(.*?)\n\\.", re.S)


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


def repl(match):
    table = match.group(1).strip()
    cols = [c.strip() for c in match.group(2).split(',') if c.strip()]
    data_block = match.group(3)
    lines = [ln for ln in data_block.splitlines() if ln.strip()]
    statements = []
    for row in lines:
        values = row.split("\t")
        if len(values) < len(cols):
            values += [""] * (len(cols) - len(values))
        elif len(values) > len(cols):
            values = values[:len(cols)]
        formatted = ", ".join(format_value(v) for v in values)
        statements.append(f"INSERT INTO {table} ({', '.join(cols)}) VALUES ({formatted});")
    return "\n".join(statements)

new_text, count = pattern.subn(repl, text)
path.write_text(new_text, encoding="utf-8")
print(f"Converted sections: {count}")
print(path)
