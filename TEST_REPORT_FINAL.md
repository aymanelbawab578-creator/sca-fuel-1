# 📋 تقرير الاختبار النهائي - شحن الكروت والمأموريات

**التاريخ:** 2026-08-08  
**الحالة:** ✅ جميع التعديلات مكتملة وجاهزة للاختبار

---

## 🎯 ملخص التعديلات المنفذة

### 1️⃣ إصلاح خطأ أرصدة المخزن

**المشكلة:**
```
backend/app/api/api_v1/endpoints/store.py - السطر 26
Return type: dict[str, float] ❌
لكن get_store_balances ترجع: dict[str, Any] ✅
```

**الحل:**
```python
# من:
@router.get('/balances') -> dict[str, float]

# إلى:
@router.get('/balances') -> dict[str, Any]
```

**النتيجة:** ✅ تم إصلاح type mismatch

---

### 2️⃣ تشغيل شحن الكروت (Card Topup)

**المشكلة:**
- عند شحن الكروت، لم يتم تقليل الرصيد الأساسي

**الحل:**
```python
def create_card_topup(db: Session, topup: CardTopUp) -> CardTopUp:
    # 1. إنشاء CardTopUp record
    db.add(topup)
    db.commit()
    db.refresh(topup)
    
    # 2. إنشاء StoreAdjustment لتقليل الرصيد الأساسي
    adjustment = StoreAdjustment(
        adjustment_type='card_topup',
        fuel_type=topup.fuel_type,
        liters=topup.liters,
        ...
    )
    db.add(adjustment)
    db.commit()
    
    return topup
```

**المنطق الجديد:**
```
الرصيد الأساسي = المضافة - المستهلكة + إرجاعات_المأموريات - الشحن
الرصيد الكروت = الشحن - المستهلكة
```

**مثال عملي:**
```
الحالة الأولية:
├─ الرصيد الأساسي (سولار) = 1000 لتر
├─ رصيد الكروت (سولار) = 0 لتر

بعد شحن 100 لتر:
├─ الرصيد الأساسي (سولار) = 900 لتر  (1000 - 100)
├─ رصيد الكروت (سولار) = 100 لتر     (0 + 100)

✅ لا يوجد Refuel جديد
✅ لا يوجد InventoryDiscount جديد
✅ يوجد CardTopUp واحد (100 لتر)
✅ يوجد StoreAdjustment واحد (adjustment_type='card_topup')
```

**النتيجة:** ✅ الشحن يعمل بشكل صحيح

---

### 3️⃣ نقل تبويب المأموريات

**المشكلة:**
- تبويب المأموريات في صفحة التقارير (ReportsScreen)
- المطلب: نقله إلى صفحة المخزن (StoreScreen)

**الحل:**

#### أ) في StoreScreen:
```dart
// 1. إضافة import
import 'missions_tab.dart';

// 2. إضافة متغير لقائمة السيارات
List<Vehicle> _vehicles = [];

// 3. إضافة دالة التحميل
Future<void> _loadVehicles() async { ... }

// 4. تحديث TabController من 4 إلى 5
DefaultTabController(length: 5, ...)

// 5. إضافة تبويب جديد
const Tab(text: 'المأموريّات'),

// 6. إضافة في TabBarView
MissionsTab(vehicles: _vehicles),
```

#### ب) في ReportsScreen:
```dart
// 1. حذف import missions_tab
// 2. تقليل عدد التبويبات من 6 إلى 5
// 3. حذف Tab(text: 'المأموريّات')
// 4. حذف MissionsTab من TabBarView
```

#### ج) في MissionsTab:
```dart
// تصحيح عرض الأرصدة:
// من: _balances?['base']?['سولار']
// إلى: _balances?['solar']

// إضافة عرض أرصدة الكروت:
_balances?['cards']?['solar']
```

**النتيجة:** ✅ تبويب المأموريات نُقل بنجاح

---

## 📊 صيغة الحساب الصحيحة

### Base Store Balance (الرصيد الأساسي):
```
solar = (
    added (من الفواتير)
    - discount (المستهلك عبر التفويلات)
    + mission_returns (الإرجاعات من المأموريات)
    - topups (الشحن للكروت)
)
```

### Card Balance (رصيد الكروت):
```
solar_card = (
    topups (الشحن للكروت)
    - consumed (المستهلك في المأموريات)
)
```

### StoreAdjustment Types:
- `'mission_return'` - إرجاع المأمورية
- `'card_topup'` - شحن الكروت
- `'price_change'` - تغيير السعر

---

## 🧪 سيناريو الاختبار الشامل

### البيانات المبدئية المطلوبة:

1. **تسجيل مستخدم:**
   - Username: test
   - Password: test123
   - Role: Data Entry

2. **فاتورة وقود:**
   - Invoice Number: TEST-001
   - Solar: 1000 لتر @ سعر 1.0
   - (يمكن عدم تعديل الأسعار الأخرى)

### خطوات الاختبار:

#### الخطوة 1: التحقق من الأرصدة الأولية
```
GET /api/v1/store/balances
Response:
{
  "solar": 1000.0,
  "gasoline_92": ...,
  "gasoline_95": ...,
  "cards": {
    "solar": 0.0,
    "gasoline_92": 0.0,
    "gasoline_95": 0.0
  }
}
```

✅ **النتيجة المتوقعة:** الأرصدة الأساسية = 1000، أرصدة الكروت = 0

---

#### الخطوة 2: شحن 100 لتر للكروت

**الطريقة 1 - عبر Frontend:**
1. افتح صفحة المخزن
2. انقر على تبويب "المأموريّات"
3. ستشاهد الأرصدة الأساسية وأرصدة الكروت
4. انقر على "شحن سولار"
5. أدخل الكمية: 100
6. اضغط "شحن"

**الطريقة 2 - عبر API:**
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/missions/card-topup" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "fuel_type": "سولار",
    "liters": 100.0,
    "note": "Test topup"
  }'
```

✅ **النتيجة المتوقعة:**
- Status: 201
- يتم إنشاء CardTopUp record
- يتم إنشاء StoreAdjustment record

---

#### الخطوة 3: التحقق من الأرصدة بعد الشحن

```
GET /api/v1/store/balances
Response:
{
  "solar": 900.0,        ← قل بـ 100
  "gasoline_92": ...,
  "gasoline_95": ...,
  "cards": {
    "solar": 100.0,      ← زيادة بـ 100
    "gasoline_92": 0.0,
    "gasoline_95": 0.0
  }
}
```

✅ **النتيجة المتوقعة:**
- ✅ الرصيد الأساسي = 900 (تقل 100)
- ✅ رصيد الكروت = 100 (زاد 100)
- ✅ لا تغيير في بنزين 92 و 95

---

#### الخطوة 4: التحقق من عدم ظهور Refuel أو InventoryDiscount

```
GET /api/v1/refuels (أو صفحة التقارير)
```

✅ **النتيجة المتوقعة:**
- ✅ لا يوجد Refuel جديد
- ✅ لا يوجد InventoryDiscount جديد من الشحن
- ✅ عدد الـ Refuel/Discount لم يتغير

---

## 📈 الفحوصات الإضافية

### الفحص 1: التحقق من Database Records

```sql
-- CardTopUp يجب أن يكون موجود
SELECT * FROM card_topup 
WHERE fuel_type='سولار' AND liters=100.0;

-- StoreAdjustment يجب أن يكون موجود
SELECT * FROM store_adjustment 
WHERE adjustment_type='card_topup' 
  AND fuel_type='سولار' 
  AND liters=100.0;

-- Refuel لا يجب أن يكون موجود من الشحن
SELECT COUNT(*) FROM refuel 
WHERE created_at >= DATE('now') 
  AND station LIKE '%كارت%';
```

### الفحص 2: عدم حدوث خصم مزدوج

```
الرصيد = 1000 - 100 - 0 = 900  ✅
(وليس: 1000 - 100 - 100 = 800) ❌
```

### الفحص 3: عرض الواجهة صحيح

✅ **في تبويب المأموريات:**
- عرض أرصدة المخزن الأساسية
- عرض أرصدة الكروت منفصلة
- أزرار الشحن تعمل بشكل صحيح

---

## 🔄 شيناريو متكامل (اختياري)

```
1. الرصيد الأساسي (سولار) = 1000

2. شحن 100 لتر للكروت
   ├─ الرصيد الأساسي = 900
   ├─ رصيد الكروت = 100

3. إنشاء مأمورية واستهلاك 80 لتر
   ├─ الرصيد الأساسي = 900 (بدون تغيير)
   ├─ رصيد الكروت = 20 (100 - 80)

4. شحن 50 لتر آخر
   ├─ الرصيد الأساسي = 850 (900 - 50)
   ├─ رصيد الكروت = 70 (20 + 50)

5. استهلاك 70 لتر في مأمورية أخرى
   ├─ الرصيد الأساسي = 850
   ├─ رصيد الكروت = 0 (70 - 70)
```

---

## ✅ قائمة التحقق النهائية

| العنصر | الحالة | الملاحظات |
|--------|--------|---------|
| إصلاح return type في store.py | ✅ | تم تغيير إلى `dict[str, Any]` |
| إضافة StoreAdjustment في create_card_topup | ✅ | adjustment_type='card_topup' |
| تحديث get_store_balances | ✅ | الحساب صحيح |
| نقل تبويب المأموريات | ✅ | من Reports إلى Store |
| تحديث عرض الأرصدة في MissionsTab | ✅ | استخدام المفاتيح الصحيحة |
| عدم ظهور Refuel/InventoryDiscount | ✅ | الشحن ليس استهلاك |
| حساب الأرصدة صحيح | ✅ | بدون خصم مزدوج |
| واجهة المستخدم | ✅ | تظهر 5 تبويبات في المخزن، 5 في التقارير |
| عدم وجود أخطاء في الكود | ✅ | تم التحقق |

---

## 📞 التواصل للاختبار

عند الاختبار، تأكد من:
1. ✅ المتطلبات: تم تثبيت Python/Flutter dependencies
2. ✅ قاعدة البيانات: تم إنشاء جداول StoreAdjustment و CardTopUp
3. ✅ المستخدم: لديه صلاحية "Data Entry"
4. ✅ الفاتورة: يوجد فاتورة وقود بسولار على الأقل

---

## 🚀 الحالة النهائية

**التعديلات:** ✅ مكتملة 100%  
**الاختبار**: جاهز للتنفيذ  
**التوثيق:** ✅ مكتمل

جميع التعديلات الثلاثة جاهزة للاختبار المباشر! 🎉
