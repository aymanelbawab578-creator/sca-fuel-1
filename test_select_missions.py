from sqlmodel import select
from app.core.config import settings
from app.db.session import SessionLocal
from app.models.mission import Mission

with SessionLocal() as db:
    try:
        missions = db.exec(select(Mission).order_by(Mission.created_at.desc())).all()
        print('missions count:', len(missions))
    except Exception as e:
        print('ERROR:', e)
        raise
