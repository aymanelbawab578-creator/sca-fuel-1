#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
تحقق من تعديلات شاشة المأمورية الجديدة
Verify New Mission Screen Modifications

التاريخ: 2026-08-08
الإصدار: 1.0
"""

import os
import re
from pathlib import Path


def check_file_exists(path: str, description: str) -> bool:
    """تحقق من وجود ملف"""
    exists = os.path.exists(path)
    status = "✅" if exists else "❌"
    print(f"{status} {description}: {path}")
    return exists


def check_file_contains(path: str, pattern: str, description: str) -> bool:
    """تحقق من أن الملف يحتوي على نص معين"""
    if not os.path.exists(path):
        print(f"❌ الملف غير موجود: {path}")
        return False
    
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
            found = pattern in content or re.search(pattern, content)
            status = "✅" if found else "❌"
            print(f"{status} {description}")
            return found
    except Exception as e:
        print(f"❌ خطأ في قراءة الملف: {e}")
        return False


def check_mission_dart():
    """تحقق من تعديلات mission_detail.dart"""
    print("\n" + "="*60)
    print("🎯 التحقق من: mission_detail.dart")
    print("="*60)
    
    path = r"c:\Users\FIRST\Desktop\sca\frontend\lib\screens\mission_detail.dart"
    checks = [
        (path, "الجزء الأول: بيانات المأمورية", True),
        (path, "_driverJobNumberController", "حقل رقم عمل السائق"),
        (path, "_directionController", "حقل اتجاه المأمورية"),
        (path, "_orderNumberController", "حقل رقم أمر التشغيل"),
        (path, "_orderDateController", "حقل تاريخ أمر التشغيل"),
        (path, "_startOdometerController", "حقل عداد البداية"),
        (path, "_endOdometerController", "حقل عداد النهاية"),
        (path, "_cardNotesController", "حقل ملاحظات الكارت"),
        (path, "ثانياً: تفويلات المأمورية", "قسم التفويلات"),
        (path, "ثالثاً: رصيد الكارت", "قسم رصيد الكارت"),
        (path, "حفظ المأمورية", "زر الحفظ"),
        (path, "حفظ وترحيل — مكتملة", "زر الترحيل النهائي"),
        (path, "DataTable", "جدول التفويلات"),
        (path, "_getRemainingBalance", "دالة حساب الرصيد المتبقي"),
        (path, "أضف تفويلة", "زر إضافة التفويلة"),
    ]
    
    results = []
    for item in checks:
        if len(item) == 2:
            path_to_check, desc = item
            results.append(check_file_exists(path_to_check, desc))
        else:
            path_to_check, pattern, desc = item
            results.append(check_file_contains(path_to_check, pattern, desc))
    
    return all(results)


def check_mission_model():
    """تحقق من تعديلات نموذج Mission"""
    print("\n" + "="*60)
    print("🎯 التحقق من: mission.py (نموذج البيانات)")
    print("="*60)
    
    path = r"c:\Users\FIRST\Desktop\sca\backend\app\models\mission.py"
    checks = [
        (path, "driver_job_number", "حقل رقم عمل السائق"),
        (path, "direction", "حقل الاتجاه"),
        (path, "order_number", "حقل رقم الأمر"),
        (path, "order_date", "حقل تاريخ الأمر"),
        (path, "start_odometer", "حقل عداد البداية"),
        (path, "end_odometer", "حقل عداد النهاية"),
        (path, "card_notes", "حقل ملاحظات الكارت"),
        (path, "MissionExpenseBase", "نموذج مصروف المأمورية"),
        (path, 'notes.*Optional', "حقل ملاحظات المصروف"),
    ]
    
    results = []
    for path_to_check, pattern, desc in checks:
        results.append(check_file_contains(path_to_check, pattern, desc))
    
    return all(results)


def check_missions_endpoints():
    """تحقق من تعديلات API endpoints"""
    print("\n" + "="*60)
    print("🎯 التحقق من: missions.py (API Endpoints)")
    print("="*60)
    
    path = r"c:\Users\FIRST\Desktop\sca\backend\app\api\api_v1\endpoints\missions.py"
    checks = [
        (path, "card_notes", "دعم حقل ملاحظات الكارت"),
        (path, "driver_job_number", "دعم رقم عمل السائق"),
        (path, "order_number", "دعم رقم الأمر"),
        (path, "start_odometer", "دعم عداد البداية"),
        (path, "end_odometer", "دعم عداد النهاية"),
        (path, "notes", "دعم ملاحظات المصروف في التصدير"),
        (path, "def update_mission", "دالة تحديث المأمورية"),
        (path, "def add_expense", "دالة إضافة مصروف"),
    ]
    
    results = []
    for path_to_check, pattern, desc in checks:
        results.append(check_file_contains(path_to_check, pattern, desc))
    
    return all(results)


def check_documentation():
    """تحقق من ملفات التوثيق"""
    print("\n" + "="*60)
    print("📄 التحقق من: ملفات التوثيق")
    print("="*60)
    
    docs = [
        (r"c:\Users\FIRST\Desktop\sca\NEW_MISSION_SCREEN_DESIGN.md", "ملف التصميم الجديد"),
        (r"c:\Users\FIRST\Desktop\sca\TEST_NEW_MISSION_SCREEN.md", "دليل الاختبار"),
    ]
    
    results = []
    for path, desc in docs:
        results.append(check_file_exists(path, desc))
    
    return all(results)


def print_summary(results: dict):
    """اطبع ملخص النتائج"""
    print("\n" + "="*60)
    print("📊 ملخص التحقق")
    print("="*60)
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    percentage = (passed / total * 100) if total > 0 else 0
    
    for check_name, result in results.items():
        status = "✅" if result else "❌"
        print(f"{status} {check_name}")
    
    print("\n" + "-"*60)
    print(f"النتيجة: {passed}/{total} ({percentage:.1f}%)")
    
    if passed == total:
        print("\n🎉 جميع الفحوصات نجحت! التصميم الجديد جاهز للاستخدام.")
    else:
        print(f"\n⚠️  {total - passed} فحص لم ينجح. يرجى مراجعة التعديلات.")
    
    return passed == total


def main():
    """الدالة الرئيسية"""
    print("\n" + "🔍 بدء التحقق من تعديلات شاشة المأمورية الجديدة")
    print("="*60)
    
    results = {
        "تحقق من mission_detail.dart": check_mission_dart(),
        "تحقق من نموذج Mission": check_mission_model(),
        "تحقق من API Endpoints": check_missions_endpoints(),
        "تحقق من ملفات التوثيق": check_documentation(),
    }
    
    success = print_summary(results)
    
    print("\n" + "="*60)
    print("انتهى التحقق 🏁")
    print("="*60 + "\n")
    
    return 0 if success else 1


if __name__ == "__main__":
    exit(main())
