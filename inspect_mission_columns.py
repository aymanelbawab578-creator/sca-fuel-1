from sqlalchemy import create_engine, text
from app.core.config import settings

engine = create_engine(settings.database_url)
try:
    with engine.connect() as conn:
        rows = conn.execute(text("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'mission' ORDER BY ordinal_position"))
        print('mission table columns:')
        for r in rows:
            print(r[0], r[1])
except Exception as e:
    print('ERROR:', e)
    raise
