import os
import sys
from pathlib import Path

import psycopg2

ROOT = Path(r'C:\Users\FIRST\Desktop\sca')
ENV_PATH = ROOT / 'backend' / '.env'
OUT_PATH = ROOT / 'backup_neon_before_supabase.sql'


def load_database_url(path: Path) -> str:
    for line in path.read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if line.startswith('DATABASE_URL='):
            return line.split('=', 1)[1].strip()
    raise RuntimeError('DATABASE_URL not found in .env')


def quote_ident(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'


def format_value(value):
    if value is None:
        return 'NULL'
    if isinstance(value, bool):
        return 'TRUE' if value else 'FALSE'
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def dump_backup(conn, out_path: Path) -> None:
    with conn.cursor() as cur:
        cur.execute('BEGIN READ ONLY')

        # Schemas
        cur.execute("""
            SELECT schema_name
            FROM information_schema.schemata
            WHERE schema_name NOT IN ('pg_catalog', 'information_schema')
            ORDER BY schema_name
        """)
        schemas = [row[0] for row in cur.fetchall()]

        lines = []
        lines.append('-- Backup generated with Python + psycopg2')
        lines.append('-- Source: backend/.env')
        lines.append('-- Read-only dump of tables, schemas, PK/FK, indexes, and data')
        lines.append('')

        for schema in schemas:
            lines.append(f'CREATE SCHEMA IF NOT EXISTS {quote_ident(schema)};')
            lines.append('')

        # Tables and data
        tables = []
        for schema in schemas:
            cur.execute("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = %s
                  AND table_type = 'BASE TABLE'
                ORDER BY table_name
            """, (schema,))
            for (table_name,) in cur.fetchall():
                tables.append((schema, table_name))

        for schema, table_name in tables:
            # Columns
            cur.execute("""
                SELECT column_name, data_type, is_nullable, column_default, udt_name
                FROM information_schema.columns
                WHERE table_schema = %s AND table_name = %s
                ORDER BY ordinal_position
            """, (schema, table_name))
            columns = cur.fetchall()
            if not columns:
                continue

            column_defs = []
            for column_name, data_type, is_nullable, column_default, udt_name in columns:
                col_type = data_type
                if data_type == 'USER-DEFINED':
                    col_type = udt_name
                nullable = '' if is_nullable == 'NO' else ' NULL'
                default = '' if not column_default else f' DEFAULT {column_default}'
                column_defs.append(f'    {quote_ident(column_name)} {col_type}{nullable}{default}')

            lines.append(f'CREATE TABLE {quote_ident(schema)}.{quote_ident(table_name)} (')
            lines.append(',\n'.join(column_defs))
            lines.append(');')
            lines.append('')

            # Primary keys
            cur.execute("""
                SELECT kcu.column_name, tc.constraint_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                  ON tc.constraint_name = kcu.constraint_name
                 AND tc.table_schema = kcu.table_schema
                WHERE tc.constraint_type = 'PRIMARY KEY'
                  AND tc.table_schema = %s
                  AND tc.table_name = %s
                ORDER BY kcu.ordinal_position
            """, (schema, table_name))
            pk_rows = cur.fetchall()
            if pk_rows:
                pk_cols = [row[0] for row in pk_rows]
                pk_name = pk_rows[0][1]
                lines.append(
                    f'ALTER TABLE {quote_ident(schema)}.{quote_ident(table_name)} '
                    f'ADD CONSTRAINT {quote_ident(pk_name)} PRIMARY KEY ({", ".join(quote_ident(c) for c in pk_cols)});'
                )
                lines.append('')

            # Foreign keys
            cur.execute("""
                SELECT tc.constraint_name, kcu.column_name, ccu.table_schema AS ref_schema, ccu.table_name AS ref_table, ccu.column_name AS ref_column
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                  ON tc.constraint_name = kcu.constraint_name
                 AND tc.table_schema = kcu.table_schema
                JOIN information_schema.constraint_column_usage ccu
                  ON tc.constraint_name = ccu.constraint_name
                 AND tc.table_schema = ccu.table_schema
                WHERE tc.constraint_type = 'FOREIGN KEY'
                  AND tc.table_schema = %s
                  AND tc.table_name = %s
                ORDER BY tc.constraint_name, kcu.ordinal_position
            """, (schema, table_name))
            fk_rows = cur.fetchall()
            if fk_rows:
                grouped = {}
                for constraint_name, column_name, ref_schema, ref_table, ref_column in fk_rows:
                    grouped.setdefault(constraint_name, []).append((column_name, ref_schema, ref_table, ref_column))
                for constraint_name, items in grouped.items():
                    local_cols = [item[0] for item in items]
                    ref_cols = [item[3] for item in items]
                    ref_schema = items[0][1]
                    ref_table = items[0][2]
                    lines.append(
                        f'ALTER TABLE {quote_ident(schema)}.{quote_ident(table_name)} '
                        f'ADD CONSTRAINT {quote_ident(constraint_name)} FOREIGN KEY ({", ".join(quote_ident(c) for c in local_cols)}) '
                        f'REFERENCES {quote_ident(ref_schema)}.{quote_ident(ref_table)} ({", ".join(quote_ident(c) for c in ref_cols)});'
                    )
                lines.append('')

            # Indexes
            cur.execute("""
                SELECT indexname, indexdef
                FROM pg_indexes
                WHERE schemaname = %s AND tablename = %s
                ORDER BY indexname
            """, (schema, table_name))
            index_rows = cur.fetchall()
            if index_rows:
                for _, indexdef in index_rows:
                    lines.append(indexdef + ';')
                lines.append('')

            # Data
            cur.execute(f'SELECT * FROM {quote_ident(schema)}.{quote_ident(table_name)}')
            rows = cur.fetchall()
            if rows:
                col_names = [desc[0] for desc in cur.description]
                values_sql = []
                for row in rows:
                    values = ', '.join(format_value(v) for v in row)
                    values_sql.append(f'({values})')
                lines.append(
                    f'INSERT INTO {quote_ident(schema)}.{quote_ident(table_name)} '
                    f'({", ".join(quote_ident(c) for c in col_names)}) VALUES'
                )
                lines.append(',\n'.join(values_sql) + ';')
                lines.append('')

        out_path.write_text('\n'.join(lines), encoding='utf-8')
        cur.execute('ROLLBACK')


def main() -> None:
    if not ENV_PATH.exists():
        print(f'ENV_NOT_FOUND: {ENV_PATH}', file=sys.stderr)
        sys.exit(1)

    DATABASE_URL = load_database_url(ENV_PATH)
    print('Connecting to database...')
    conn = psycopg2.connect(DATABASE_URL)
    try:
        dump_backup(conn, OUT_PATH)
    finally:
        conn.close()

    print(f'BACKUP_FILE={OUT_PATH}')
    print(f'BACKUP_SIZE_BYTES={OUT_PATH.stat().st_size}')


if __name__ == '__main__':
    main()
