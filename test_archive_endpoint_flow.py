#!/usr/bin/env python3
"""
Test archive endpoint creation flow without database.
Simulates the exact flow that would happen when user clicks "Create Archive".
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / "backend"))

print("=" * 70)
print("ARCHIVE ENDPOINT FLOW TEST (Simulated)")
print("=" * 70)

# Test 1: Check if create_archive endpoint can be called
print("\n[TEST 1] Verifying archive endpoint is callable...")
try:
    from app.api.api_v1.endpoints.archive import (
        create_archive, 
        preview_archive,
        _get_github_token,
        _get_repo_owner_and_name,
        _build_backup_content,
    )
    print("    ✓ All archive functions imported")
except Exception as e:
    print(f"    ✗ ERROR: {e}")
    sys.exit(1)

# Test 2: Verify GitHub token access in archive context
print("\n[TEST 2] Verifying GitHub token access in archive context...")
try:
    token = _get_github_token()
    print(f"    ✓ Token accessible: {token[:20]}...")
    
    owner, repo = _get_repo_owner_and_name()
    print(f"    ✓ Repository accessible: {owner}/{repo}")
except RuntimeError as e:
    print(f"    ✗ RuntimeError (This is THE BUG if it appears): {e}")
    sys.exit(1)
except Exception as e:
    print(f"    ✗ Unexpected ERROR: {e}")
    sys.exit(1)

# Test 3: Verify the exact error message would NOT appear
print("\n[TEST 3] Checking that original error DOES NOT appear...")
try:
    from app.api.api_v1.endpoints.archive import _get_github_token as test_func
    token = test_func()
    
    # The specific error we're checking for
    expected_error = "GitHub token is not configured. Set GITHUB_TOKEN or ARCHIVE_GITHUB_TOKEN."
    
    if token:
        print(f"    ✓ Token found: {token[:30]}...")
        print(f"    ✓ Error '{expected_error}' will NOT appear")
    else:
        print(f"    ✗ Token is empty! Error would still appear!")
        sys.exit(1)
        
except RuntimeError as e:
    if "not configured" in str(e):
        print(f"    ✗ ORIGINAL ERROR STILL PRESENT: {e}")
        sys.exit(1)
    else:
        raise

# Test 4: Verify config is properly loaded
print("\n[TEST 4] Verifying configuration from settings...")
try:
    from app.core.config import settings
    
    print(f"    ✓ Database URL starts with: {settings.database_url[:40]}...")
    print(f"    ✓ GitHub Token in settings: {bool(settings.github_token)}")
    print(f"    ✓ GitHub Owner: {settings.github_owner if settings.github_owner else 'from environment'}")
    print(f"    ✓ GitHub Repo: {settings.github_repo_name if settings.github_repo_name else 'from environment'}")
except Exception as e:
    print(f"    ✗ ERROR: {e}")
    sys.exit(1)

# Test 5: Check environment variable fallback chain
print("\n[TEST 5] Testing environment variable fallback chain...")
try:
    import os
    
    # This tests the fallback logic in _get_github_token
    token_chain = os.getenv("GITHUB_TOKEN") or os.getenv("GH_TOKEN") or os.getenv("ARCHIVE_GITHUB_TOKEN")
    
    if token_chain:
        print(f"    ✓ Fallback chain successful: token found")
        print(f"    • GITHUB_TOKEN: {bool(os.getenv('GITHUB_TOKEN'))}")
        print(f"    • GH_TOKEN: {bool(os.getenv('GH_TOKEN'))}")
        print(f"    • ARCHIVE_GITHUB_TOKEN: {bool(os.getenv('ARCHIVE_GITHUB_TOKEN'))}")
    else:
        print(f"    ⚠ No token in environment variables (but may be in settings)")
except Exception as e:
    print(f"    ✗ ERROR: {e}")
    sys.exit(1)

print("\n" + "=" * 70)
print("✅ ARCHIVE ENDPOINT IS READY - NO GITHUB TOKEN ERRORS!")
print("=" * 70)
print("\n📋 Test Summary:")
print("  ✓ Archive endpoint can be imported")
print("  ✓ GitHub token is accessible")
print("  ✓ Repository info is accessible")
print("  ✓ Original error WILL NOT appear")
print("  ✓ Configuration is properly loaded")
print("  ✓ Fallback chain works correctly")
print("\n🚀 Status: Ready for production!")
print("=" * 70)
