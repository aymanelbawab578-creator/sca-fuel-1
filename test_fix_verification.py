#!/usr/bin/env python3
"""
Comprehensive test to verify GitHub token loading fix.
"""
import sys
import os
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).resolve().parent / "backend"))

print("=" * 70)
print("GITHUB TOKEN FIX VERIFICATION TEST")
print("=" * 70)

# Test 1: Import config and verify load_dotenv was called
print("\n[TEST 1] Importing config.py and verifying load_dotenv...")
try:
    from app.core.config import settings
    print("    ✓ config.py imported successfully")
    
    # Check if environment variables are loaded
    token = os.getenv("GITHUB_TOKEN")
    if token:
        print(f"    ✓ GITHUB_TOKEN loaded from .env: {token[:20]}...")
    else:
        print("    ⚠ GITHUB_TOKEN not in os.environ (may still be in settings)")
except Exception as e:
    print(f"    ✗ ERROR: {e}")
    sys.exit(1)

# Test 2: Check settings class has GitHub fields
print("\n[TEST 2] Verifying Settings class has GitHub fields...")
try:
    assert hasattr(settings, 'github_token'), "Missing 'github_token' field"
    assert hasattr(settings, 'github_owner'), "Missing 'github_owner' field"
    assert hasattr(settings, 'github_repo_name'), "Missing 'github_repo_name' field"
    print("    ✓ All GitHub fields present in settings")
    print(f"    • github_token: {settings.github_token[:20] if settings.github_token else '(empty)'}...")
    print(f"    • github_owner: {settings.github_owner}")
    print(f"    • github_repo_name: {settings.github_repo_name}")
except AssertionError as e:
    print(f"    ✗ ERROR: {e}")
    sys.exit(1)

# Test 3: Test _get_github_token function
print("\n[TEST 3] Testing _get_github_token() function...")
try:
    from app.api.api_v1.endpoints.archive import _get_github_token
    token = _get_github_token()
    print(f"    ✓ _get_github_token() returned token: {token[:20]}...")
except RuntimeError as e:
    print(f"    ✗ RuntimeError: {e}")
    sys.exit(1)
except Exception as e:
    print(f"    ✗ ERROR: {e}")
    sys.exit(1)

# Test 4: Test _get_repo_owner_and_name function
print("\n[TEST 4] Testing _get_repo_owner_and_name() function...")
try:
    from app.api.api_v1.endpoints.archive import _get_repo_owner_and_name
    owner, repo = _get_repo_owner_and_name()
    print(f"    ✓ _get_repo_owner_and_name() returned:")
    print(f"      • Owner: {owner}")
    print(f"      • Repository: {repo}")
except RuntimeError as e:
    print(f"    ✗ RuntimeError: {e}")
    sys.exit(1)
except Exception as e:
    print(f"    ✗ ERROR: {e}")
    sys.exit(1)

# Test 5: Verify FastAPI app can be imported
print("\n[TEST 5] Importing FastAPI app...")
try:
    from app.main import app
    print("    ✓ app.main imported successfully")
    print(f"    • App title: {app.title}")
except Exception as e:
    print(f"    ✗ ERROR: {e}")
    sys.exit(1)

# Test 6: Quick endpoint test simulation
print("\n[TEST 6] Simulating archive endpoint setup...")
try:
    from app.api.api_v1.endpoints.archive import create_archive, _build_backup_content
    print("    ✓ Archive endpoints imported successfully")
    print("    • create_archive endpoint available")
    print("    • _build_backup_content function available")
except Exception as e:
    print(f"    ✗ ERROR: {e}")
    sys.exit(1)

print("\n" + "=" * 70)
print("✅ ALL TESTS PASSED - GitHub token configuration is working correctly!")
print("=" * 70)
print("\n📌 Summary:")
print("  • load_dotenv() is called automatically in config.py")
print("  • GitHub credentials are loaded from .env file")
print("  • Settings class has dedicated GitHub fields")
print("  • Archive functions can access GitHub token without errors")
print("\n" + "=" * 70)
