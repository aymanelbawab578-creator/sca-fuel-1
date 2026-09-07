from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)
resp = client.post('/api/v1/auth/token', data={'username':'admin','password':'admin123'})
if resp.status_code!=200:
    raise SystemExit('login failed')
headers = {'Authorization': f"Bearer {resp.json()['access_token']}"}

payload = {'fuel_type':'سولار','liters':5.0,'note':'test topup'}
res = client.post('/api/v1/missions/card-topup', json=payload, headers=headers)
print('card-topup', res.status_code, res.json())

bal = client.get('/api/v1/store/balances', headers=headers)
print('balances after topup', bal.status_code, bal.json())
