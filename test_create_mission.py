from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)
resp = client.post('/api/v1/auth/token', data={'username':'admin','password':'admin123'})
print('login', resp.status_code)
if resp.status_code!=200:
    raise SystemExit('login failed')
token = resp.json()['access_token']
headers = {'Authorization': f'Bearer {token}'}

payload = {
    'vehicle_id': 274,
    'charged_liters': 10.0,
    'fuel_type': 'سولار',
    'driver_name': 'Test Driver',
    'driver_job_number': '123'
}
res = client.post('/api/v1/missions/', json=payload, headers=headers)
print('create mission', res.status_code, res.text)
