# 🔑 مرجع الثوابت والقيم المستخدمة

## 📌 ملخص سريع

هذا المرجع يوضح جميع الثوابت والقيم المستخدمة في التعديلات الثلاث.

---

## 1️⃣ أنواع الوقود (Fuel Types)

```python
# كل مكان في الكود يستخدم هذه القيم الثابتة:
FUEL_TYPES = {
    'سولار': 'solar',
    'بنزين 92': 'gasoline_92',
    'بنزين 95': 'gasoline_95',
}

# في الـ database و API:
- 'سولار'      (Arabic)
- 'بنزين 92'   (Arabic)
- 'بنزين 95'   (Arabic)

# في Python/JSON:
- 'solar'
- 'gasoline_92'
- 'gasoline_95'
```

---

## 2️⃣ Adjustment Types (StoreAdjustment)

```python
# adjustment_type values:
'mission_return'  # إرجاع المأمورية
'card_topup'      # شحن الكروت (NEW)
'price_change'    # تغيير السعر
```

---

## 3️⃣ API Endpoints

```
# Store Endpoints
GET    /api/v1/store/balances
GET    /api/v1/store/add-invoices
POST   /api/v1/store/add-invoices
GET    /api/v1/store/add-invoices/{id}
PUT    /api/v1/store/add-invoices/{id}
DELETE /api/v1/store/add-invoices/{id}
POST   /api/v1/store/price-change
GET    /api/v1/store/price-change/logs
DELETE /api/v1/store/price-change/logs/{id}
GET    /api/v1/store/settlement-report

# Missions Endpoints
POST   /api/v1/missions/card-topup                ← NEW
GET    /api/v1/missions
GET    /api/v1/missions/{id}
POST   /api/v1/missions
PUT    /api/v1/missions/{id}
POST   /api/v1/missions/{id}/complete
POST   /api/v1/missions/{id}/expenses
GET    /api/v1/missions/export
```

---

## 4️⃣ Database Tables & Models

```python
# StoreAdjustment
class StoreAdjustment(SQLModel):
    id: Optional[int] = None
    created_at: date = date.today()
    fuel_type: str                          # 'سولار', etc.
    liters: float
    adjustment_type: str                    # 'mission_return', 'card_topup', etc.
    source: str = 'price_change'
    note: Optional[str] = None

# CardTopUp
class CardTopUp(SQLModel):
    id: Optional[int] = None
    created_at: date = date.today()
    fuel_type: str                          # 'سولار', etc.
    liters: float
    note: Optional[str] = None

# CardConsumption
class CardConsumption(SQLModel):
    id: Optional[int] = None
    created_at: date = date.today()
    fuel_type: str                          # 'سولار', etc.
    liters: float
    mission_id: Optional[int] = None
    refuel_id: Optional[int] = None
    note: Optional[str] = None

# AddInvoice
class AddInvoice(SQLModel):
    id: Optional[int] = None
    invoice_number: str
    created_at: date = date.today()
    solar_quantity: float = 0.0
    solar_price: float = 0.0
    solar_total: float = 0.0
    gasoline_92_quantity: float = 0.0
    gasoline_92_price: float = 0.0
    gasoline_92_total: float = 0.0
    gasoline_95_quantity: float = 0.0
    gasoline_95_price: float = 0.0
    gasoline_95_total: float = 0.0
    total_amount: float = 0.0
    details: Optional[str] = None
    is_deleted: bool = False
    deleted_at: Optional[datetime] = None

# InventoryDiscount
class InventoryDiscount(SQLModel):
    id: Optional[int] = None
    refuel_id: Optional[int] = None         # Foreign key
    vehicle_id: int                         # Foreign key
    fuel_type: str                          # 'سولار', etc.
    current_odometer: float
    liters: float
    actual_percentage: float
    created_at: date = date.today()
    is_excess: bool = False
    is_illogical: bool = False
    station: Optional[str] = None
```

---

## 5️⃣ Response Format من /store/balances

```json
{
  "solar": 900.0,
  "gasoline_92": 1000.0,
  "gasoline_95": 1000.0,
  "cards": {
    "solar": 100.0,
    "gasoline_92": 0.0,
    "gasoline_95": 0.0
  }
}
```

### شرح:
- `solar, gasoline_92, gasoline_95` = الأرصدة الأساسية
- `cards` = أرصدة الكروت الذكي
- النوع: `dict[str, Any]` (تم تصحيحه من `dict[str, float]`)

---

## 6️⃣ Payload للـ Card Topup

```json
{
  "fuel_type": "سولار",
  "liters": 100.0,
  "note": "Test topup",
  "created_at": "2026-08-08"  # Optional
}
```

### Response:
```json
{
  "id": 1,
  "created_at": "2026-08-08",
  "fuel_type": "سولار",
  "liters": 100.0,
  "note": "Test topup"
}
```

---

## 7️⃣ صيغ الحساب

### Base Store Balance:
```
base = added - discount + mission_returns - topups

مثال:
- added = 1000 (من الفاتورة)
- discount = 0 (لم تُستهلك)
- mission_returns = 0 (لم ترجع)
- topups = 100 (شُحنت)

base = 1000 - 0 + 0 - 100 = 900
```

### Card Balance:
```
cards = topups - consumed

مثال:
- topups = 100 (شُحنت)
- consumed = 0 (لم تُستهلك)

cards = 100 - 0 = 100
```

### Balance with Missions:
```
بعد إكمال مأمورية استهلكت 80 لتر:
- consumed = 80
- mission_return = 80 (يُرجع للأساسي)

base = 1000 - 0 + 80 - 100 = 980
cards = 100 - 80 = 20
```

---

## 8️⃣ مسارات الملفات الرئيسية

```
Backend:
├─ backend/app/api/api_v1/endpoints/
│  ├─ store.py                    ← تعديل return type
│  └─ missions.py                 ← endpoint card-topup
├─ backend/app/crud/
│  ├─ store.py                    ← create_card_topup + get_store_balances
│  └─ mission.py                  ← complete_mission logic
├─ backend/app/models/
│  └─ store.py                    ← CardTopUp, StoreAdjustment models
└─ backend/tests/
   └─ test_card_topup_functionality.py  ← اختبارات

Frontend:
├─ frontend/lib/screens/
│  ├─ store_screen.dart           ← إضافة MissionsTab
│  ├─ reports_screen.dart         ← حذف MissionsTab
│  └─ missions_tab.dart           ← إصلاح عرض الأرصدة
└─ frontend/lib/services/
   └─ api_service.dart            ← cardTopup method
```

---

## 9️⃣ أسماء Functions و Methods

```python
# Backend Functions:
get_store_balances(db: Session) -> dict[str, Any]
create_card_topup(db: Session, topup: CardTopUp) -> CardTopUp
complete_mission(db: Session, mission_id: int) -> Mission

# CRUD Functions:
create_inventory_discount()
create_add_invoice()
update_add_invoice()
delete_add_invoice()
apply_price_change()
get_settlement_report()
```

---

## 🔟 Status Codes و Error Handling

```python
# Success:
200 OK                  # GET request
201 Created             # POST request
204 No Content          # DELETE request

# Errors:
400 Bad Request         # Invalid payload
404 Not Found           # Resource not found
500 Internal Error      # Server error
```

---

## 1️⃣1️⃣ مفاتيح JSON المهمة

```python
# Balance Response:
'solar'           # float - الرصيد الأساسي سولار
'gasoline_92'     # float - الرصيد الأساسي بنزين 92
'gasoline_95'     # float - الرصيد الأساسي بنزين 95
'cards'           # dict  - أرصدة الكروت
  ├─ 'solar'      # float
  ├─ 'gasoline_92'# float
  └─ 'gasoline_95'# float

# CardTopUp Response:
'id'              # int
'created_at'      # string (YYYY-MM-DD)
'fuel_type'       # string
'liters'          # float
'note'            # string
```

---

## 1️⃣2️⃣ متغيرات Frontend المهمة

```dart
// In StoreScreen:
List<Vehicle> _vehicles = [];
double _solarBalance = 0.0;
double _gasoline92Balance = 0.0;
double _gasoline95Balance = 0.0;

// TabController:
DefaultTabController(length: 5, ...)

// TabBar tabs:
[
  Tab(text: 'المتابعة'),
  Tab(text: 'الفواتير'),
  Tab(text: 'تقرير التسوية'),
  Tab(text: 'تغيير السعر'),
  Tab(text: 'المأموريّات'),  // NEW
]

// In MissionsTab:
Map<String, dynamic>? _balances;
List<Map<String, dynamic>> _missions = [];

// Access balances:
_balances?['solar']              // float - base balance
_balances?['cards']?['solar']    // float - card balance
_balances?['gasoline_92']        // float - base balance
_balances?['cards']?['gasoline_92']  // float - card balance
```

---

## 🔗 Dependencies و Imports المستخدمة

```python
# Backend:
from sqlmodel import Session, select, func
from app.models.store import CardTopUp, StoreAdjustment, AddInvoice
from app.crud.store import create_card_topup, get_store_balances

# Frontend:
import 'missions_tab.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';
```

---

## 📊 ملخص الثوابت

| الثابت | القيمة | النوع | المكان |
|-------|--------|-------|--------|
| Fuel Type | 'سولار' | string | Database |
| Fuel Type | 'بنزين 92' | string | Database |
| Fuel Type | 'بنزين 95' | string | Database |
| Adjustment Type | 'mission_return' | string | Database |
| Adjustment Type | 'card_topup' | string | Database |
| Adjustment Type | 'price_change' | string | Database |
| Station | 'تموين بالكارت الذكي' | string | Refuel |
| Station | 'كارت ذكي' | string | InventoryDiscount |
| Tab Count (Store) | 5 | int | Frontend |
| Tab Count (Reports) | 5 | int | Frontend |
| Tab Index (Missions) | 4 | int | Frontend |
| Return Type | dict[str, Any] | type | API |

---

## ✅ التحقق النهائي

- ✅ جميع المفاتيح والثوابت موثقة
- ✅ جميع الأنواع (types) محددة
- ✅ جميع الـ endpoints موثقة
- ✅ جميع الحسابات موضحة

**هذا المرجع كامل وشامل! 📚**
