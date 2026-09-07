from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

resp = client.get('/api/v1/store/balances')
print('/api/v1/store/balances', resp.status_code, resp.json())

resp2 = client.get('/api/v1/missions')
print('/api/v1/missions', resp2.status_code)
try:
    print(resp2.json())
except Exception as e:
    print('missions json parse error:', e)
