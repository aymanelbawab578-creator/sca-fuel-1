#!/usr/bin/env python3
"""
Export only the `public` schema from a Postgres DATABASE_URL found in .env
Creates `backup_clean_public.sql` in the repository root using pg_dump.

Notes:
- Requires `pg_dump` available on PATH.
- Intentionally restricts to schema `public` to avoid pg_* and information_schema.
"""
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import re
import json

try:
    import psycopg2
    from psycopg2 import sql
except Exception:
    psycopg2 = None


def read_database_url_from_env(env_path: Path) -> str:
    if not env_path.exists():
        raise FileNotFoundError(f".env file not found at {env_path}")
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("DATABASE_URL="):
            _, val = line.split("=", 1)
            val = val.strip().strip('"').strip("'")
            return val
    raise KeyError("DATABASE_URL not found in .env")


def locate_env_file(cwd: Path) -> Path:
    # Look for .env in common locations: cwd, cwd/backend, cwd/app
    candidates = [cwd / ".env", cwd / "backend" / ".env", cwd / "app" / ".env"]
    for p in candidates:
        if p.exists():
            return p
    # Fallback: try to find any file named .env in immediate subdirectories
    for child in cwd.iterdir():
        if child.is_dir():
            candidate = child / ".env"
            if candidate.exists():
                return candidate
    # last resort: cwd/.env (will raise later)
    return cwd / ".env"


def main():
    cwd = Path.cwd()
    env_path = locate_env_file(cwd)
    try:
        db_url = read_database_url_from_env(env_path)
    except Exception as e:
        print(f"FAIL: could not read DATABASE_URL from .env: {e}")
        sys.exit(2)

    out_file = cwd / "backup_clean_public.sql"

    pg_dump_path = shutil.which("pg_dump")
    if not pg_dump_path:
        print("pg_dump not found on PATH — falling back to Python exporter using psycopg2.")
        if not psycopg2:
            print("FAIL: psycopg2 not installed; cannot perform fallback export.\nPlease install PostgreSQL client tools or psycopg2.")
            sys.exit(3)
        # perform python fallback export
        try:
            export_via_psycopg2(db_url, out_file)
        except Exception as e:
            print("FAIL: Python fallback export failed:", e)
            sys.exit(6)
        size = out_file.stat().st_size
        print(f"SUCCESS: created {out_file.name} SIZE: {size}")
        print("REPORT: هل نجح؟ نعم")
        print(f"REPORT: حجم الملف بالبايت {size}")
        return

    # Build pg_dump command to export only public schema, with data, constraints, sequences.
    # --no-owner and --no-privileges avoid ownership/ACL statements which may fail on restore.
    cmd = [
        pg_dump_path,
        "--schema=public",
        "--no-owner",
        "--no-privileges",
        "--format=plain",
        "--file",
        str(out_file),
        db_url,
    ]

    print("Running: ", " ".join(shlex.quote(p) for p in cmd))
    try:
        completed = subprocess.run(cmd, check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print("FAIL: pg_dump failed with exit code", e.returncode)
        if e.stdout:
            print("STDOUT:\n", e.stdout)
        if e.stderr:
            print("STDERR:\n", e.stderr)
        sys.exit(4)
    except FileNotFoundError:
        print("FAIL: pg_dump executable not found or not executable.")
        sys.exit(3)

    if not out_file.exists():
        print("FAIL: expected output file not created:", out_file)
        sys.exit(5)

    size = out_file.stat().st_size
    print(f"SUCCESS: created {out_file.name} SIZE: {size}")
    # Print exact expected two-line report so the caller (assistant) can parse it.
    print("REPORT: هل نجح؟ نعم")
    print(f"REPORT: حجم الملف بالبايت {size}")


def export_via_psycopg2(db_url: str, out_file: Path):
    conn = psycopg2.connect(dsn=db_url)
    cur = conn.cursor()
    with out_file.open("w", encoding="utf-8") as f:
        f.write("-- Exported public schema (clean)\n")
        f.write("SET search_path = public;\n\n")

        # Export ENUM types defined in public schema
        cur.execute("""
            SELECT t.typname, array_agg(e.enumlabel ORDER BY e.enumsortorder) as labels
            FROM pg_type t
            JOIN pg_namespace n ON t.typnamespace = n.oid
            JOIN pg_enum e ON t.oid = e.enumtypid
            WHERE n.nspname = 'public'
            GROUP BY t.typname
            ORDER BY t.typname
        """)
        enums = cur.fetchall()
        for typname, labels in enums:
            esc_labels = [l.replace("'", "''") for l in labels]
            labels_sql = ", ".join("'{}'".format(l) for l in esc_labels)
            f.write(f"-- Type: {typname}\n")
            f.write(f"DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = '{typname}' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) THEN CREATE TYPE \"{typname}\" AS ENUM ({labels_sql}); END IF; END$$;\n\n")

        # get tables in public schema excluding system tables
        cur.execute("""
            SELECT tablename
            FROM pg_catalog.pg_tables
            WHERE schemaname = 'public'
              AND tablename NOT LIKE 'pg_%'
              AND tablename NOT LIKE 'sql_%'
            ORDER BY tablename
        """)
        tables = [r[0] for r in cur.fetchall()]

        # First pass: collect sequences referenced by column defaults across all tables
        sequences_emitted = set()
        for tbl in tables:
            cur.execute(sql.SQL("SELECT column_default FROM information_schema.columns WHERE table_schema='public' AND table_name=%s"), [tbl])
            for (default,) in cur.fetchall():
                if default:
                    m = re.search(r"nextval\('\s*([^']+)\s*'", str(default))
                    if m:
                        sequences_emitted.add(m.group(1))

        # Open output file and write header, enums, then sequences
        with out_file.open("w", encoding="utf-8") as f:
            f.write("-- Exported public schema (clean)\n")
            f.write("SET search_path = public;\n\n")

            # Export ENUM types defined in public schema
            cur.execute("""
                SELECT t.typname, array_agg(e.enumlabel ORDER BY e.enumsortorder) as labels
                FROM pg_type t
                JOIN pg_namespace n ON t.typnamespace = n.oid
                JOIN pg_enum e ON t.oid = e.enumtypid
                WHERE n.nspname = 'public'
                GROUP BY t.typname
                ORDER BY t.typname
            """)
            enums = cur.fetchall()
            for typname, labels in enums:
                esc_labels = [l.replace("'", "''") for l in labels]
                labels_sql = ", ".join("'{}'".format(l) for l in esc_labels)
                f.write(f"-- Type: {typname}\n")
                f.write(f"DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = '{typname}' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) THEN CREATE TYPE \"{typname}\" AS ENUM ({labels_sql}); END IF; END$$;\n\n")

            # Emit all sequences up-front
            for seq in sorted(sequences_emitted):
                # split schema-qualified names
                if '.' in seq:
                    schema, name = seq.split('.', 1)
                    f.write(f"-- Sequence: {schema}.{name}\n")
                    f.write(f"CREATE SEQUENCE IF NOT EXISTS \"{schema}\".\"{name}\";\n")
                    # get last_value
                    try:
                        cur.execute(sql.SQL("SELECT last_value, is_called FROM {}.{}") .format(sql.Identifier(schema), sql.Identifier(name)))
                        last_value, is_called = cur.fetchone()
                        f.write(f"SELECT pg_catalog.setval('{schema}.{name}', {last_value}, {'true' if is_called else 'false'});\n\n")
                    except Exception:
                        f.write("-- failed to read sequence value\n\n")
                else:
                    name = seq
                    f.write(f"-- Sequence: {name}\n")
                    f.write(f"CREATE SEQUENCE IF NOT EXISTS \"{name}\";\n")
                    try:
                        cur.execute(sql.SQL("SELECT last_value, is_called FROM {}") .format(sql.Identifier(name)))
                        last_value, is_called = cur.fetchone()
                        f.write(f"SELECT pg_catalog.setval('{name}', {last_value}, {'true' if is_called else 'false'});\n\n")
                    except Exception:
                        f.write("-- failed to read sequence value\n\n")

            # after sequences, proceed to create tables and data
            for tbl in tables:
            # columns
            cur.execute(sql.SQL("SELECT column_name, data_type, is_nullable, column_default, character_maximum_length, numeric_precision, numeric_scale, udt_name FROM information_schema.columns WHERE table_schema='public' AND table_name=%s ORDER BY ordinal_position"), [tbl])
            cols = cur.fetchall()
            col_defs = []
            col_names = []
            for col in cols:
                name, data_type, is_nullable, default, char_max, num_prec, num_scale, udt = col
                col_names.append(name)
                # Resolve type name, handling user-defined types and arrays
                if data_type in ("character varying", "character") and char_max:
                    typ = f"{data_type}({char_max})"
                elif data_type == "numeric" and num_prec is not None:
                    typ = f"numeric({num_prec},{num_scale})"
                elif data_type == 'USER-DEFINED':
                    # use udt_name (actual type name) for user-defined types
                    typ = udt
                elif data_type == 'ARRAY':
                    # udt for arrays starts with _typename
                    elem = udt.lstrip('_')
                    # if element is user-defined, quote it
                    if re.match(r"^[a-zA-Z_][a-zA-Z0-9_]*$", elem):
                        typ = f"{elem}[]"
                    else:
                        typ = f"{udt}[]"
                else:
                    typ = data_type

                # For user-defined types, use quoted identifier to preserve case
                if data_type == 'USER-DEFINED':
                    typ = f'"{typ}"'
                parts = [f'"{name}" {typ}']
                if default is not None:
                    parts.append(f"DEFAULT {default}")
                if is_nullable == 'NO':
                    parts.append("NOT NULL")
                col_defs.append(" ".join(parts))

            f.write(f"-- Table: {tbl}\n")
            f.write(f"CREATE TABLE IF NOT EXISTS \"{tbl}\" (\n")
            f.write(",\n".join("    " + d for d in col_defs))
            f.write("\n);\n\n")

            # constraints
            cur.execute(sql.SQL("SELECT conname, pg_get_constraintdef(c.oid) as condef FROM pg_constraint c JOIN pg_class t ON c.conrelid = t.oid JOIN pg_namespace n ON t.relnamespace = n.oid WHERE n.nspname='public' AND t.relname=%s AND c.contype IN ('p','u','f','c')"), [tbl])
            for conname, condef in cur.fetchall():
                f.write(f"ALTER TABLE ONLY \"{tbl}\" ADD CONSTRAINT {conname} {condef};\n")
            f.write("\n")

            # data
            cur.execute(sql.SQL("SELECT * FROM public.{}") .format(sql.Identifier(tbl)))
            rows = cur.fetchall()
            if rows:
                cols_list = ", ".join([f'"{n}"' for n in col_names])
                for row in rows:
                    vals = []
                    for v in row:
                        if isinstance(v, (dict, list)):
                            v = json.dumps(v)
                        vals.append(cur.mogrify("%s", (v,)).decode("utf-8"))
                    f.write(f"INSERT INTO \"{tbl}\" ({cols_list}) VALUES ({', '.join(vals)});\n")
                f.write("\n")

        # emit sequences if detected
        for seq in sorted(sequences_emitted):
            # seq may be schema-qualified
            seq_name = seq
            cur.execute(sql.SQL("SELECT last_value, is_called FROM {}".format(sql.Identifier(seq_name).as_string(cur))))
            try:
                last_value, is_called = cur.fetchone()
            except Exception:
                # try without schema quoting
                cur.execute(sql.SQL("SELECT last_value, is_called FROM {}".format(seq_name)))
                last_value, is_called = cur.fetchone()
            f.write(f"-- Sequence: {seq_name}\n")
            f.write(f"CREATE SEQUENCE IF NOT EXISTS {seq_name};\n")
            f.write(f"SELECT pg_catalog.setval('{seq_name}', {last_value}, {'true' if is_called else 'false'});\n\n")

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
