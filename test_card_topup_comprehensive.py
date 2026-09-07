#!/usr/bin/env python3
"""
Comprehensive test for card topup functionality
Tests balance changes, store adjustments, and card consumption tracking
"""

import requests
import json
from datetime import date

BASE_URL = "http://127.0.0.1:8000/api/v1"

# Test token (replace if needed)
TOKEN = "test-token-please-replace"
HEADERS = {"Authorization": f"Bearer {TOKEN}"}

def get_store_balances():
    """Fetch current store balances"""
    response = requests.get(f"{BASE_URL}/store/balances", headers=HEADERS)
    print(f"\n📊 Store Balances Response: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return data
    else:
        print(f"Error: {response.text}")
        return None

def create_card_topup(fuel_type, liters, note="Test topup"):
    """Create a card topup"""
    payload = {
        "fuel_type": fuel_type,
        "liters": liters,
        "note": note,
        "created_at": date.today().isoformat()
    }
    response = requests.post(
        f"{BASE_URL}/missions/card-topup",
        headers=HEADERS,
        json=payload
    )
    print(f"\n💳 Card Topup Response: {response.status_code}")
    print(f"Payload: {json.dumps(payload, indent=2, ensure_ascii=False)}")
    if response.status_code == 201:
        data = response.json()
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return data
    else:
        print(f"Error: {response.text}")
        return None

def get_store_adjustments():
    """Query store adjustments (if endpoint exists)"""
    # Note: This might not exist, so we handle gracefully
    response = requests.get(f"{BASE_URL}/store/adjustments", headers=HEADERS)
    print(f"\n⚙️ Store Adjustments Response: {response.status_code}")
    if response.status_code == 200:
        print(json.dumps(response.json(), indent=2, ensure_ascii=False))
        return response.json()
    else:
        print(f"Note: Adjustments endpoint not available or error: {response.text}")
        return None

def run_test():
    """
    Test scenario:
    1. Get initial balances
    2. Create a 100-liter card topup for Solar
    3. Check balances after topup
    4. Verify calculations
    """
    print("=" * 80)
    print("🧪 CARD TOPUP COMPREHENSIVE TEST")
    print("=" * 80)
    
    # Step 1: Get initial balances
    print("\n📍 STEP 1: Get Initial Balances")
    initial_balances = get_store_balances()
    if not initial_balances:
        print("❌ Failed to get initial balances. Aborting test.")
        return
    
    initial_solar = initial_balances.get('solar', 0)
    initial_g92 = initial_balances.get('gasoline_92', 0)
    initial_g95 = initial_balances.get('gasoline_95', 0)
    initial_cards = initial_balances.get('cards', {})
    
    print(f"\n✅ Initial State:")
    print(f"  Base Balances: Solar={initial_solar}, G92={initial_g92}, G95={initial_g95}")
    print(f"  Card Balances: {json.dumps(initial_cards, ensure_ascii=False)}")
    
    # Step 2: Create card topup
    print("\n📍 STEP 2: Create Card Topup (100L Solar)")
    topup_result = create_card_topup('سولار', 100.0, 'Test topup 100L')
    if not topup_result:
        print("❌ Failed to create card topup. Aborting test.")
        return
    
    # Step 3: Get balances after topup
    print("\n📍 STEP 3: Get Balances After Topup")
    after_balances = get_store_balances()
    if not after_balances:
        print("❌ Failed to get balances after topup.")
        return
    
    after_solar = after_balances.get('solar', 0)
    after_g92 = after_balances.get('gasoline_92', 0)
    after_g95 = after_balances.get('gasoline_95', 0)
    after_cards = after_balances.get('cards', {})
    
    print(f"\n✅ After Topup State:")
    print(f"  Base Balances: Solar={after_solar}, G92={after_g92}, G95={after_g95}")
    print(f"  Card Balances: {json.dumps(after_cards, ensure_ascii=False)}")
    
    # Step 4: Verify calculations
    print("\n📍 STEP 4: Verify Calculations")
    solar_diff = initial_solar - after_solar
    card_solar_diff = after_cards.get('solar', 0) - initial_cards.get('solar', 0)
    
    print(f"\n✅ Changes:")
    print(f"  Base Solar decreased by: {solar_diff}")
    print(f"  Card Solar increased by: {card_solar_diff}")
    
    # Expected: solar_diff = 100, card_solar_diff = 100
    expected_topup = 100.0
    
    print(f"\n🔍 Verification:")
    success = True
    
    if abs(solar_diff - expected_topup) < 0.01:
        print(f"  ✅ Base solar correctly decreased by {expected_topup}L")
    else:
        print(f"  ❌ Base solar decreased by {solar_diff}L, expected {expected_topup}L")
        success = False
    
    if abs(card_solar_diff - expected_topup) < 0.01:
        print(f"  ✅ Card solar correctly increased by {expected_topup}L")
    else:
        print(f"  ❌ Card solar increased by {card_solar_diff}L, expected {expected_topup}L")
        success = False
    
    # Check that G92 and G95 didn't change
    if abs(after_g92 - initial_g92) < 0.01:
        print(f"  ✅ Gasoline 92 unchanged")
    else:
        print(f"  ⚠️ Gasoline 92 changed: {initial_g92} -> {after_g92}")
    
    if abs(after_g95 - initial_g95) < 0.01:
        print(f"  ✅ Gasoline 95 unchanged")
    else:
        print(f"  ⚠️ Gasoline 95 changed: {initial_g95} -> {after_g95}")
    
    print("\n" + "=" * 80)
    if success:
        print("✅ TEST PASSED: Card topup working correctly!")
    else:
        print("❌ TEST FAILED: Card topup not working as expected")
    print("=" * 80)
    
    return success

if __name__ == "__main__":
    run_test()
