#!/usr/bin/env python3
"""
Test script to diagnose GitHub token loading issue.
"""
import os
import sys
from pathlib import Path

print("=" * 60)
print("ENVIRONMENT VARIABLE LOADING TEST")
print("=" * 60)

# Test 1: os.getenv before any loading
print("\n[1] Checking environment variables WITHOUT load_dotenv:")
print(f"    GITHUB_TOKEN: {os.getenv('GITHUB_TOKEN')}")
print(f"    GH_TOKEN: {os.getenv('GH_TOKEN')}")
print(f"    ARCHIVE_GITHUB_TOKEN: {os.getenv('ARCHIVE_GITHUB_TOKEN')}")

# Test 2: Load .env using python-dotenv
print("\n[2] Loading .env with load_dotenv()...")
from dotenv import load_dotenv
env_file_path = Path(__file__).resolve().parent / "backend" / ".env"
print(f"    Env file path: {env_file_path}")
print(f"    File exists: {env_file_path.exists()}")

if env_file_path.exists():
    load_dotenv(env_file_path)
    print(f"    ✓ load_dotenv() called")

# Test 3: os.getenv after loading
print("\n[3] Checking environment variables AFTER load_dotenv:")
token = os.getenv('GITHUB_TOKEN')
print(f"    GITHUB_TOKEN: {token[:20] + '...' if token else 'None'}")
print(f"    GH_TOKEN: {os.getenv('GH_TOKEN')}")
print(f"    ARCHIVE_GITHUB_TOKEN: {os.getenv('ARCHIVE_GITHUB_TOKEN')}")

# Test 4: Check pydantic-settings
print("\n[4] Checking pydantic-settings from config:")
sys.path.insert(0, str(Path(__file__).resolve().parent / "backend"))
from app.core.config import settings
print(f"    DATABASE_URL: {settings.database_url[:50]}...")

# Test 5: Try archive token function
print("\n[5] Testing _get_github_token() function:")
try:
    from app.api.api_v1.endpoints.archive import _get_github_token
    token = _get_github_token()
    print(f"    ✓ Token found: {token[:20]}...")
except RuntimeError as e:
    print(f"    ✗ ERROR: {e}")

print("\n" + "=" * 60)
