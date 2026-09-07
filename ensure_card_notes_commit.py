from sqlalchemy import create_engine, text, inspect
from app.core.config import settings

engine = create_engine(settings.database_url)
try:
    with engine.begin() as conn:
        inspector = inspect(conn)
        if inspector.has_table('mission'):
            cols = {c['name'] for c in inspector.get_columns('mission')}
            print('mission columns before:', sorted(cols))
            if 'card_notes' not in cols:
                conn.execute(text('ALTER TABLE mission ADD COLUMN card_notes TEXT'))
                print('ALTER executed')
            else:
                print('card_notes already existed')
        else:
            print('mission table not found')
    # new connection to list columns after commit
    with engine.connect() as conn2:
        rows = conn2.execute(text("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'mission' ORDER BY ordinal_position"))
        print('mission columns after:')
        for r in rows:
            print(r[0], r[1])
except Exception as e:
    print('ERROR:', e)
    raise
