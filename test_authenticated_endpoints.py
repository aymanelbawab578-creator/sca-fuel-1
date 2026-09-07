from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

# login
resp = client.post('/api/v1/auth/token', data={'username':'admin','password':'admin123'})
print('token status', resp.status_code, resp.json())
if resp.status_code == 200:
    token = resp.json().get('access_token')
    headers = {'Authorization': f'Bearer {token}'}
    r1 = client.get('/api/v1/store/balances', headers=headers)
    print('/api/v1/store/balances', r1.status_code, r1.json())
    r2 = client.get('/api/v1/missions', headers=headers)
    print('/api/v1/missions', r2.status_code)
    try:
        print(r2.json())
    except Exception as e:
        print('missions json error', e)
else:
    print('login failed')
