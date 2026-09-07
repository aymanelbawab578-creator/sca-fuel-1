# ⚡ اختبار فوري - التحقق من التعديلات

## 📋 الاختبار السريع (5 دقائق)

### المطلوب:
- ✅ توكن أو مستخدم بصلاحيات
- ✅ فاتورة وقود (سولار 1000 لتر على الأقل)
- ✅ curl أو Postman أو Python

---

## 1️⃣ الاختبار #1: التحقق من البلانس API

```bash
# الأمر:
curl -X GET "http://127.0.0.1:8000/api/v1/store/balances" \
  -H "Authorization: Bearer YOUR_TOKEN"

# التوقع:
{
  "solar": 1000.0,              # الرصيد الأساسي
  "gasoline_92": 0.0,
  "gasoline_95": 0.0,
  "cards": {                     # أرصدة الكروت (NEW)
    "solar": 0.0,
    "gasoline_92": 0.0,
    "gasoline_95": 0.0
  }
}

# النتيجة:
✅ إذا اتبعت هذا الشكل = النعديل الأول صحيح
❌ إذا حصلت على خطأ = مشكلة في التعديل
```

---

## 2️⃣ الاختبار #2: شحن الكروت

```bash
# الأمر:
curl -X POST "http://127.0.0.1:8000/api/v1/missions/card-topup" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fuel_type": "سولار",
    "liters": 100.0,
    "note": "Test topup"
  }'

# التوقع:
{
  "id": 1,
  "created_at": "2026-08-08",
  "fuel_type": "سولار",
  "liters": 100.0,
  "note": "Test topup"
}

# النتيجة:
✅ Status 201 = شحن نجح
❌ Status 400/500 = خطأ في التنفيذ
```

---

## 3️⃣ الاختبار #3: التحقق من تغير الأرصدة

```bash
# الأمر نفسه من الاختبار #1:
curl -X GET "http://127.0.0.1:8000/api/v1/store/balances" \
  -H "Authorization: Bearer YOUR_TOKEN"

# التوقع:
{
  "solar": 900.0,               # قل من 1000 إلى 900 ✅
  "gasoline_92": 0.0,
  "gasoline_95": 0.0,
  "cards": {
    "solar": 100.0,            # زاد من 0 إلى 100 ✅
    "gasoline_92": 0.0,
    "gasoline_95": 0.0
  }
}

# النتيجة:
✅ solar: 1000 → 900 = صحيح
✅ cards.solar: 0 → 100 = صحيح
❌ solar: 800 أو أقل = خصم مزدوج (خطأ)
❌ cards.solar: 0 = شحن لم يحدث (خطأ)
```

---

## 4️⃣ الاختبار #4: التحقق من عدم وجود Refuel/Discount

```bash
# الأمر (إذا كان الـ endpoint موجود):
curl -X GET "http://127.0.0.1:8000/api/v1/refuels" \
  -H "Authorization: Bearer YOUR_TOKEN"

# التوقع:
- لا يجب أن يظهر refuel جديد من الشحن
- عدد الـ refuels لم يتغير

# أو تحقق من قاعدة البيانات:
SELECT COUNT(*) FROM refuel 
WHERE station LIKE '%كارت%';  -- يجب أن يكون 0 أو محدود
```

---

## 5️⃣ الاختبار #5: الواجهة الرسومية

### في StoreScreen (صفحة المخزن):

1. **انقر على "المأموريّات":**
   ```
   يجب أن تشاهد:
   ├─ ✅ أرصدة المخزن: سولار 900
   ├─ ✅ أرصدة الكروت: سولار 100
   ├─ ✅ أزرار الشحن (شحن سولار، شحن 92، شحن 95)
   └─ ✅ قائمة المأموريات
   ```

2. **شحن آخر (50 لتر سولار):**
   ```
   الأرصدة بعد الشحن يجب أن تكون:
   ├─ أرصدة المخزن: سولار 850 (900 - 50)
   └─ أرصدة الكروت: سولار 150 (100 + 50)
   ```

### في ReportsScreen (صفحة التقارير):

1. **فحص عدد التبويبات:**
   ```
   يجب أن يكون:
   ├─ التقرير اليومي
   ├─ تقرير النسبة
   ├─ تقرير الفترة
   ├─ تقرير كميات الوقود
   └─ حاسبة الفواتير
   
   ❌ لا تبويب "المأموريّات" هنا
   ```

---

## 🐍 اختبار Python (اختياري)

```python
import requests
import json

BASE_URL = "http://127.0.0.1:8000/api/v1"
TOKEN = "YOUR_TOKEN"
HEADERS = {"Authorization": f"Bearer {TOKEN}"}

# 1. الحصول على الأرصدة الأولية
print("1️⃣ الأرصدة الأولية:")
resp = requests.get(f"{BASE_URL}/store/balances", headers=HEADERS)
initial = resp.json()
print(json.dumps(initial, indent=2, ensure_ascii=False))

# 2. شحن 100 لتر
print("\n2️⃣ شحن 100 لتر سولار:")
payload = {
    "fuel_type": "سولار",
    "liters": 100.0,
    "note": "Test"
}
resp = requests.post(f"{BASE_URL}/missions/card-topup", 
                     headers=HEADERS, json=payload)
print(f"Status: {resp.status_code}")
print(json.dumps(resp.json(), indent=2, ensure_ascii=False))

# 3. الأرصدة بعد الشحن
print("\n3️⃣ الأرصدة بعد الشحن:")
resp = requests.get(f"{BASE_URL}/store/balances", headers=HEADERS)
after = resp.json()
print(json.dumps(after, indent=2, ensure_ascii=False))

# 4. التحقق
print("\n4️⃣ التحقق:")
initial_solar = initial['solar']
after_solar = after['solar']
card_solar = after['cards']['solar']

print(f"✅ سولار الأساسي: {initial_solar} → {after_solar} (فرق: {initial_solar - after_solar})")
print(f"✅ سولار الكروت: {card_solar}")

if abs(initial_solar - after_solar - 100) < 0.01:
    print("✅ النتيجة صحيحة!")
else:
    print("❌ خطأ في الحساب!")
```

---

## ✅ جدول النتائج

| الاختبار | الأمر | النتيجة المتوقعة | الحالة |
|---------|------|----------------|--------|
| #1 | GET /balances | JSON مع nested 'cards' | ✅ |
| #2 | POST /card-topup | Status 201 | ✅ |
| #3 | GET /balances | solar↓, cards↑ | ✅ |
| #4 | Refuel count | 0 جديد | ✅ |
| #5 | UI - المأموريات | موجود في StoreScreen | ✅ |
| #5 | UI - ReportsScreen | 5 تبويبات فقط | ✅ |

---

## 🚨 حل المشاكل الشائعة

### المشكلة: خطأ في البلانس API
```
Error: type object 'float' cannot be interpreted as an integer

الحل: تأكد أن return type تم تغييره إلى dict[str, Any]
```

### المشكلة: الشحن لا يغير الأرصدة
```
solar: 1000 → 1000 (لم يتغير)

الحل: تأكد أن create_card_topup يضيف StoreAdjustment
```

### المشكلة: الخصم مرتين
```
solar: 1000 → 800 (خصم 200 بدل 100)

الحل: تأكد أنه يتم استخدام CardTopUp فقط، ليس StoreAdjustment
```

### المشكلة: المأموريات تعطي خطأ في الأرصدة
```
Error: 'NoneType' object is not subscriptable

الحل: تأكد أن missions_tab يستخدم المفاتيح الصحيحة:
_balances?['solar']  (ليس _balances?['base']?['سولار'])
```

---

## 📞 المعايير الأخرى للفحص

- ✅ لا توجد رسائل خطأ في Console
- ✅ جميع الصور تحمل بشكل صحيح
- ✅ لا توجد تحذيرات في Dart Analysis
- ✅ لا توجد أخطاء في Python type checking

---

## 🎯 الخلاصة

**اختبر 5 نقاط فقط:**
1. ✅ API balance يعيد dict مع cards
2. ✅ POST card-topup ترجع 201
3. ✅ الأرصدة تتغير بشكل صحيح
4. ✅ لا توجد refuels إضافية
5. ✅ UI تعرض الأرصدة بشكل صحيح

**إذا كانت جميع الخمس ✅، فكل شيء يعمل بشكل صحيح! 🎉**
