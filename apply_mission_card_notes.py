from sqlalchemy import create_engine, inspect, text
from app.core.config import settings

engine = create_engine(settings.database_url)
try:
    with engine.connect() as conn:
        inspector = inspect(conn)
        if inspector.has_table('mission'):
            cols = {c['name'] for c in inspector.get_columns('mission')}
            print('mission columns before:', sorted(cols))
            if 'card_notes' not in cols:
                conn.execute(text('ALTER TABLE mission ADD COLUMN card_notes TEXT'))
                print('Added card_notes')
            else:
                print('card_notes already exists')
        else:
            print('mission table not found')
except Exception as e:
    print('ERROR:', e)
    raise
