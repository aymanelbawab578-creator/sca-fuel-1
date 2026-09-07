from pathlib import Path
import re

path = Path(r"c:\Users\FIRST\Desktop\sca\backup_neon_before_supabase.sql")
text = path.read_text(encoding="utf-8")
lines = text.splitlines()
for i, line in enumerate(lines):
    if line.startswith("COPY "):
        print("FOUND", i, line)
        m = re.match(r'^COPY\s+(.+?)\s*\((.*?)\)\s+FROM\s+stdin;$', line)
        print("MATCH", bool(m))
        if m:
            print("TABLE", m.group(1).strip())
            print("COLS", m.group(2).split(','))
            j = i + 1
            while j < len(lines):
                if lines[j] == r"\.":
                    print("TERMINATOR", j)
                    break
                print("DATA", repr(lines[j]))
                j += 1
            break
        break
