import os
import re
import sys
from pathlib import Path

try:
    import psycopg2
    from psycopg2 import sql
except Exception as e:
    print(f'IMPORT_ERROR: {e}', file=sys.stderr)
    sys.exit(1)

root = Path(r'C:\Users\FIRST\Desktop\sca')
env_path = root / 'backend' / '.env'
if not env_path.exists():
    print(f'ENV_NOT_FOUND: {env_path}', file=sys.stderr)
    sys.exit(1)

def load_database_url(path: Path) -> str:
    for line in path.read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if line.startswith('DATABASE_URL='):
            return line.split('=', 1)[1].strip()
    raise RuntimeError('DATABASE_URL not found in .env')

DATABASE_URL = load_database_url(env_path)
out_path = root / 'backup_neon_before_supabase.sql'

print(f'Connecting to database...')
conn = psycopg2.connect(DATABASE_URL)
conn.autocommit = False
cur = conn.cursor()

# Read-only transaction
cur.execute('BEGIN READ ONLY')

# Get all schemas
cur.execute("""
    SELECT schema_name
    FROM information_schema.schemata
    WHERE schema_name NOT IN ('pg_catalog', 'information_schema')
    ORDER BY schema_name
""")
schemas = [row[0] for row in cur.fetchall()]

# Get all tables in all schemas
all_tables = []
for schema in schemas:
    cur.execute("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = %s
          AND table_type = 'BASE TABLE'
        ORDER BY table_name
    """, (schema,))
    tables = [row[0] for row in cur.fetchall()]
    for table in tables:
        all_tables.append((schema, table))

lines = []
lines.append('-- Backup generated with Python + psycopg2')
lines.append('-- Database URL source: backend/.env')
lines.append('')

# Dump schema objects and data using simple SQL generation
for schema, table in all_tables:
    # Table definition
    cur.execute("""
        SELECT column_name, data_type, is_nullable, column_default, udt_name
        FROM information_schema.columns
        WHERE table_schema = %s AND table_name = %s
        ORDER BY ordinal_position
    """, (schema, table))
    cols = cur.fetchall()
    if not cols:
        continue

    col_defs = []
    for column_name, data_type, is_nullable, column_default, udt_name in cols:
        col_type = data_type
        if data_type == 'USER-DEFINED':
            col_type = udt_name
        nullable = '' if is_nullable == 'NO' else ' NULL'
        default = ''
        if column_default:
            default = f" DEFAULT {column_default}"
        col_defs.append(f'    {quote_ident(column_name)} {col_type}{nullable}{default}')

    lines.append(f'CREATE TABLE {quote_ident(schema)}.{quote_ident(table)} (')
    lines.append(',\n'.join(col_defs))
    lines.append(');')
    lines.append('')

    # Primary keys
    cur.execute("""
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
         AND tc.table_schema = kcu.table_schema
        WHERE tc.constraint_type = 'PRIMARY KEY'
          AND tc.table_schema = %s
          AND tc.table_name = %s
        ORDER BY kcu.ordinal_position
    """, (schema, table))
    pk_cols = [row[0] for row in cur.fetchall()]
    if pk_cols:
        pk_sql = ', '.join(quote_ident(c) for c in pk_cols)
        lines.append(f'ALTER TABLE {quote_ident(schema)}.{quote_ident(table)} ADD PRIMARY KEY ({pk_sql});')
        lines.append('')

    # Data rows
    cur.execute(sql.SQL('SELECT * FROM {}.{}').format(
        sql.Identifier(schema),
        sql.Identifier(table)
    ))
    rows = cur.fetchall()
    if rows:
        col_names = [desc[0] for desc in cur.description]
        values_sql = []
        for row in rows:
            vals = []
            for value in row:
                if value is None:
                    vals.append('NULL')
                elif isinstance(value, (int, float)):
                    vals.append(str(value))
                else:
                    vals.append("'" + str(value).replace("'", "''") + "'")
            values_sql.append('(' + ', '.join(vals) + ')')
        lines.append(f'INSERT INTO {quote_ident(schema)}.{quote_ident(table)} ({", ".join(quote_ident(c) for c in col_names)}) VALUES')
        lines.append(',\n'.join(values_sql) + ';')
        lines.append('')

# Foreign keys, indexes, sequences, constraints are omitted by this simple script because the environment is restricted.
# We still create a SQL file for backup purposes based on table and row data.

out_path.write_text('\n'.join(lines), encoding='utf-8')

cur.execute('ROLLBACK')
cur.close()
conn.close()

print(f'BACKUP_FILE={out_path}')
print(f'BACKUP_SIZE_BYTES={out_path.stat().st_size}')
