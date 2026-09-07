#!/usr/bin/env python3
"""
Quick verification script for Card Topup implementation
Run this to verify all changes are in place
"""

import subprocess
import sys
from pathlib import Path

# Color codes
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
END = '\033[0m'

def check_file_contains(filepath, text, description):
    """Check if a file contains specific text"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            if text in content:
                print(f"{GREEN}✅{END} {description}")
                return True
            else:
                print(f"{RED}❌{END} {description}")
                print(f"   Expected: {text[:50]}...")
                return False
    except Exception as e:
        print(f"{RED}❌{END} {description}")
        print(f"   Error: {e}")
        return False

def main():
    base_path = Path("/c/Users/FIRST/Desktop/sca")
    
    print(f"\n{BLUE}{'='*80}{END}")
    print(f"{BLUE}🔍 التحقق من التعديلات{END}")
    print(f"{BLUE}{'='*80}{END}\n")
    
    checks = []
    
    # Check 1: Store.py balance type
    print(f"{YELLOW}1. فحص إصلاح return type في store.py{END}")
    result = check_file_contains(
        base_path / "backend/app/api/api_v1/endpoints/store.py",
        "-> dict[str, Any]",
        "تم تغيير return type من dict[str, float] إلى dict[str, Any]"
    )
    checks.append(result)
    
    # Check 2: create_card_topup implementation
    print(f"\n{YELLOW}2. فحص تنفيذ create_card_topup مع StoreAdjustment{END}")
    result = check_file_contains(
        base_path / "backend/app/crud/store.py",
        "adjustment_type='card_topup'",
        "تم إضافة StoreAdjustment مع adjustment_type='card_topup'"
    )
    checks.append(result)
    
    # Check 3: Store screen imports missions_tab
    print(f"\n{YELLOW}3. فحص import missions_tab في StoreScreen{END}")
    result = check_file_contains(
        base_path / "frontend/lib/screens/store_screen.dart",
        "import 'missions_tab.dart'",
        "تم إضافة import لـ missions_tab في StoreScreen"
    )
    checks.append(result)
    
    # Check 4: Store screen has 5 tabs
    print(f"\n{YELLOW}4. فحص عدد التبويبات في StoreScreen{END}")
    result = check_file_contains(
        base_path / "frontend/lib/screens/store_screen.dart",
        "length: 5",
        "تم تغيير DefaultTabController إلى 5 تبويبات"
    )
    checks.append(result)
    
    # Check 5: Reports screen has 5 tabs (was 6)
    print(f"\n{YELLOW}5. فحص عدد التبويبات في ReportsScreen{END}")
    result = check_file_contains(
        base_path / "frontend/lib/screens/reports_screen.dart",
        "TabController(length: 5",
        "تم تقليل عدد التبويبات في ReportsScreen إلى 5"
    )
    checks.append(result)
    
    # Check 6: Reports screen removed missions_tab import
    print(f"\n{YELLOW}6. فحص حذف import missions_tab من ReportsScreen{END}")
    try:
        with open(base_path / "frontend/lib/screens/reports_screen.dart", 'r', encoding='utf-8') as f:
            content = f.read()
            if "import 'missions_tab.dart'" not in content:
                print(f"{GREEN}✅{END} تم حذف import missions_tab من ReportsScreen")
                checks.append(True)
            else:
                print(f"{RED}❌{END} يجب حذف import missions_tab من ReportsScreen")
                checks.append(False)
    except Exception as e:
        print(f"{RED}❌{END} خطأ في فحص ReportsScreen: {e}")
        checks.append(False)
    
    # Check 7: MissionsTab uses correct balance keys
    print(f"\n{YELLOW}7. فحص استخدام مفاتيح الأرصدة الصحيحة في MissionsTab{END}")
    result = check_file_contains(
        base_path / "frontend/lib/screens/missions_tab.dart",
        "_balances?['solar']",
        "تم تصحيح عرض الأرصدة لاستخدام _balances?['solar']"
    )
    checks.append(result)
    
    # Check 8: MissionsTab shows card balances
    print(f"\n{YELLOW}8. فحص عرض أرصدة الكروت في MissionsTab{END}")
    result = check_file_contains(
        base_path / "frontend/lib/screens/missions_tab.dart",
        "_balances?['cards']?['solar']",
        "تم إضافة عرض أرصدة الكروت"
    )
    checks.append(result)
    
    # Summary
    print(f"\n{BLUE}{'='*80}{END}")
    total = len(checks)
    passed = sum(checks)
    failed = total - passed
    
    if failed == 0:
        print(f"{GREEN}🎉 جميع الفحوصات نجحت! ({passed}/{total}){END}")
        print(f"{GREEN}{'='*80}{END}\n")
        return 0
    else:
        print(f"{RED}⚠️ بعض الفحوصات فشلت: {passed}/{total} نجح{END}")
        print(f"{RED}{'='*80}{END}\n")
        return 1

if __name__ == "__main__":
    sys.exit(main())
