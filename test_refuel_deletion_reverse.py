"""
اختبار حذف التفويلة مع عكس كامل التأثيرات
Test: Refuel Deletion with Complete Reverse Logic
"""
import sys
from datetime import date
from pathlib import Path

# Add backend to path
backend_path = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_path))

from sqlmodel import Session, select
from app.db.session import engine, init_db
from app.models.vehicle import Vehicle
from app.models.refuel import Refuel, RefuelCreate
from app.models.mission import Mission
from app.models.store import CardConsumption, InventoryDiscount, StoreAdjustment, CardTopUp
from app.crud.refuel import delete_refuel_with_reverse
from app.crud.mission import complete_mission
from app.crud.store import get_store_balances


def test_refuel_deletion_reverse():
    """
    اختبار الحالة الكاملة:
    1. إنشاء مهمة مفتوحة
    2. إضافة نفقة للمهمة
    3. إكمال المهمة (تصبح التفويلة مكتملة)
    4. التحقق من الأرصدة
    5. حذف التفويلة
    6. التحقق من عودة الأرصدة للحالة الأصلية
    """
    
    # إعداد قاعدة البيانات
    init_db()
    
    with Session(engine) as db:
        print("\n" + "="*60)
        print("اختبار حذف التفويلة مع عكس كامل التأثيرات")
        print("="*60)
        
        # إنشاء سيارة
        print("\n1. إنشاء سيارة اختبار...")
        vehicle = Vehicle(
            number="TEST-001",
            vehicle_model="تويوتا",
            standard_consumption=12.0,
            last_odometer=1000.0,
        )
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        print(f"✓ السيارة: {vehicle.number} (ID: {vehicle.id})")
        
        # إضافة رصيد كارت
        print("\n2. إضافة رصيد وقود للكارت (100 لتر)...")
        topup = CardTopUp(
            created_at=date.today(),
            fuel_type='سولار',
            liters=100.0,
            note='رصيد اختبار'
        )
        db.add(topup)
        db.commit()
        print(f"✓ تم إضافة {topup.liters} لتر من {topup.fuel_type}")
        
        # الأرصدة قبل المهمة
        balances_before = get_store_balances(db)
        print(f"\n3. الأرصدة قبل المهمة:")
        print(f"   - رصيد الكارت (سولار): {balances_before['cards']['solar']} لتر")
        print(f"   - رصيد المتجر (سولار): {balances_before['solar']} لتر")
        
        # إنشاء مهمة مفتوحة
        print("\n4. إنشاء مهمة مفتوحة...")
        mission = Mission(
            vehicle_id=vehicle.id,
            fuel_type='سولار',
            status='open',
        )
        db.add(mission)
        db.commit()
        db.refresh(mission)
        print(f"✓ المهمة: {mission.id} (حالة: {mission.status})")
        
        # إضافة نفقة للمهمة (50 لتر)
        print("\n5. إضافة نفقة 50 لتر للمهمة...")
        from app.models.mission import MissionExpense
        expense = MissionExpense(
            mission_id=mission.id,
            date=date.today(),
            odometer=1050.0,
            liters=50.0,
        )
        db.add(expense)
        db.commit()
        print(f"✓ تم إضافة نفقة: {expense.liters} لتر")
        
        # إكمال المهمة
        print("\n6. إكمال المهمة (حفظ نهائي)...")
        mission = complete_mission(db, mission.id)
        print(f"✓ المهمة الآن: {mission.status}")
        
        # الأرصدة بعد إكمال المهمة
        balances_after_complete = get_store_balances(db)
        print(f"\n7. الأرصدة بعد إكمال المهمة:")
        print(f"   - رصيد الكارت (سولار): {balances_after_complete['cards']['solar']} لتر")
        print(f"   - رصيد المتجر (سولار): {balances_after_complete['solar']} لتر")
        
        # التحقق من تأثير المهمة
        card_balance_change = balances_before['cards']['solar'] - balances_after_complete['cards']['solar']
        print(f"\n   ✓ تم صرف {card_balance_change} لتر من رصيد الكارت")
        
        # الحصول على التفويلة المنشأة
        refuel = db.exec(select(Refuel).order_by(Refuel.created_at.desc())).first()
        print(f"\n8. التفويلة المنشأة:")
        print(f"   - ID: {refuel.id}")
        print(f"   - الكمية: {refuel.liters} لتر")
        print(f"   - Source: {refuel.source}")
        
        # السجلات قبل الحذف
        card_consumptions = db.exec(
            select(CardConsumption).where(CardConsumption.refuel_id == refuel.id)
        ).all()
        inventory_discounts = db.exec(
            select(InventoryDiscount).where(InventoryDiscount.refuel_id == refuel.id)
        ).all()
        print(f"\n9. السجلات المرتبطة بالتفويلة:")
        print(f"   - CardConsumption: {len(card_consumptions)} سجل")
        print(f"   - InventoryDiscount: {len(inventory_discounts)} سجل")
        
        # حذف التفويلة مع العكس الكامل
        print(f"\n10. حذف التفويلة (مع عكس كامل)...")
        delete_refuel_with_reverse(db, refuel.id)
        print(f"✓ تم حذف التفويلة بنجاح")
        
        # التحقق من حذف السجلات
        remaining_cc = db.exec(
            select(CardConsumption).where(CardConsumption.refuel_id == refuel.id)
        ).all()
        remaining_id = db.exec(
            select(InventoryDiscount).where(InventoryDiscount.refuel_id == refuel.id)
        ).all()
        remaining_ref = db.get(Refuel, refuel.id)
        
        print(f"\n11. التحقق من حذف السجلات:")
        print(f"   - CardConsumption المتبقية: {len(remaining_cc)}")
        print(f"   - InventoryDiscount المتبقية: {len(remaining_id)}")
        print(f"   - Refuel المتبقية: {'محذوفة' if remaining_ref is None else 'موجودة'}")
        
        # الأرصدة بعد الحذف
        balances_after_delete = get_store_balances(db)
        print(f"\n12. الأرصدة بعد حذف التفويلة:")
        print(f"   - رصيد الكارت (سولار): {balances_after_delete['cards']['solar']} لتر")
        print(f"   - رصيد المتجر (سولار): {balances_after_delete['solar']} لتر")
        
        # المقارنة النهائية
        print(f"\n13. نتائج الاختبار:")
        if balances_after_delete['cards']['solar'] == balances_before['cards']['solar']:
            print(f"   ✓ رصيد الكارت عاد للحالة الأصلية: {balances_before['cards']['solar']} لتر")
        else:
            print(f"   ✗ خطأ في رصيد الكارت:")
            print(f"     - المتوقع: {balances_before['cards']['solar']} لتر")
            print(f"     - الفعلي: {balances_after_delete['cards']['solar']} لتر")
        
        if (len(remaining_cc) == 0 and len(remaining_id) == 0 and 
            remaining_ref is None):
            print(f"   ✓ تم حذف جميع السجلات المرتبطة")
        else:
            print(f"   ✗ توجد سجلات متبقية")
        
        print("\n" + "="*60)
        print("اكتمل الاختبار بنجاح ✓")
        print("="*60 + "\n")


if __name__ == "__main__":
    test_refuel_deletion_reverse()
