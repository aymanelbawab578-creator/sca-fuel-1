# 🔧 الكود المعدل - نسخة كاملة

## الملف 1: Backend - `missions.py` endpoint

### 📁 الموقع:
`backend/app/api/api_v1/endpoints/missions.py`

### 📝 الكود الكامل (الجزء المعدل):

```python
@router.get("/", response_model=List[MissionRead])
def list_missions(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    # الترتيب: المأموريات المفتوحة أولاً، ثم المكتملة (من الأحدث إلى الأقدم)
    # ('open' يأتي بعد 'completed' أبجديًا، لذا نستخدم desc() لجعل 'open' أولاً)
    missions = db.exec(
        select(Mission)
        .options(selectinload(Mission.expenses))
        .order_by(
            Mission.status.desc(),  # open يأتي أولاً (أبجديًا: o > c)
            Mission.created_at.desc()  # ثم الأحدث أولاً
        )
    ).all()
    # Attach vehicle_number attribute to each mission for clarity in frontend
    for m in missions:
        try:
            v = get_vehicle_by_id(db, m.vehicle_id)
            if v:
                setattr(m, 'vehicle_number', v.number)
        except Exception:
            setattr(m, 'vehicle_number', '')
    return missions
```

### 🔍 التغييرات:

#### قبل:
```python
missions = db.exec(select(Mission)...order_by(Mission.created_at.desc())).all()
```

#### بعد:
```python
missions = db.exec(
    select(Mission)...order_by(
        Mission.status.desc(),
        Mission.created_at.desc()
    )
).all()
```

---

## الملف 2: Frontend - `missions_tab.dart` DataTable

### 📁 الموقع:
`frontend/lib/screens/missions_tab.dart`

### 📝 الكود الكامل (الجزء المعدل):

```dart
DataTable(
  columns: const [
    DataColumn(label: Text('م.')),
    DataColumn(label: Text('التاريخ')),
    DataColumn(label: Text('رقم السيارة')),
    DataColumn(label: Text('الوجهة')),
    DataColumn(label: Text('كمية الشحن')),
    DataColumn(label: Text('الحالة')),  // ← عمود جديد
    DataColumn(label: Text('تعديل')),
    DataColumn(label: Text('حذف')),
  ],
  rows: _missions.asMap().entries.map((entry) {
    final idx = entry.key;
    final m = entry.value;
    final created = m['created_at'] ?? '';
    final createdDate = created.isNotEmpty ? DateTime.tryParse(created) : null;
    
    // ← كود جديد للحالة
    final status = m['status']?.toString() ?? 'open';
    final statusText = status == 'completed' ? 'مكتملة' : 'مفتوحة';
    final statusColor = status == 'completed' ? Colors.green : Colors.orange;
    
    return DataRow(cells: [
      DataCell(Text('${idx + 1}')),
      DataCell(Text(createdDate != null ? DateFormat('yyyy-MM-dd').format(createdDate) : '')),
      DataCell(Text(m['vehicle_number']?.toString() ?? (m['vehicle_id']?.toString() ?? ''))),
      DataCell(Text(m['direction']?.toString() ?? '')),
      DataCell(Text((m['charged_liters'] ?? 0).toString())),
      
      // ← خلية جديدة: عمود الحالة
      DataCell(Chip(
        label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: statusColor,
      )),
      
      DataCell(IconButton(
        icon: const Icon(Icons.edit, size: 20),
        onPressed: () async {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => MissionDetailScreen(missionId: m['id']))).then((_) => _loadMissions());
        },
      )),
      DataCell(IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: () async {
          final should = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('حذف المأمورية'),
              content: const Text('هل أنت متأكد من حذف هذه المأمورية؟ سيتم حذفها من الواجهة.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
                ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('حذف')),
              ],
            ),
          );
          if (should != true) return;
          final token = Provider.of<AuthProvider>(context, listen: false).token!;
          try {
            await ApiService.deleteMission(token, m['id']);
            await _loadMissions();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المأمورية')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: ${e.toString()}')));
          }
        },
      )),
    ]);
  }).toList(),
)
```

### 🔍 التغييرات:

#### التغيير الأول: إضافة عمود جديد في `columns`:
```dart
// قبل:
DataColumn(label: Text('تعديل')),
DataColumn(label: Text('حذف')),

// بعد:
DataColumn(label: Text('الحالة')),  // ← جديد
DataColumn(label: Text('تعديل')),
DataColumn(label: Text('حذف')),
```

#### التغيير الثاني: إضافة منطق الحالة في `rows`:
```dart
// قبل: لا يوجد تحديد للحالة

// بعد:
final status = m['status']?.toString() ?? 'open';
final statusText = status == 'completed' ? 'مكتملة' : 'مفتوحة';
final statusColor = status == 'completed' ? Colors.green : Colors.orange;
```

#### التغيير الثالث: إضافة `DataCell` جديد:
```dart
// قبل:
DataCell(Text((m['charged_liters'] ?? 0).toString())),
DataCell(IconButton(...)),  // تعديل

// بعد:
DataCell(Text((m['charged_liters'] ?? 0).toString())),
DataCell(Chip(  // ← جديد
  label: Text(statusText, ...),
  backgroundColor: statusColor,
)),
DataCell(IconButton(...)),  // تعديل
```

---

## الملخص الفني

### الملفات المعدلة: 2
```
✏️ backend/app/api/api_v1/endpoints/missions.py
✏️ frontend/lib/screens/missions_tab.dart
```

### الأسطر المعدلة:

**Backend**:
- تعديل الـ order_by من سطر واحد إلى سطرين
- إضافة comment شارح

**Frontend**:
- إضافة عمود جديد في columns (1 سطر)
- إضافة logic للحالة (3 أسطر)
- إضافة DataCell جديد (4 أسطر)

### الإجمالي:
- ~10-15 سطر كود جديد/معدل فقط
- لا migrations أو تعديلات على النماذج

---

## الاختبار السريع

### 1. تشغيل Backend:
```bash
cd backend
python -m uvicorn app.main:app --reload
```

### 2. زيارة الـ Endpoint:
```bash
GET http://127.0.0.1:8000/api/v1/missions/
Authorization: Bearer <token>
```

### 3. التحقق من الترتيب في الـ Response:
```json
[
  {
    "id": 1,
    "status": "open",
    "created_at": "2026-08-16",
    "...": "..."
  },
  {
    "id": 3,
    "status": "open",
    "created_at": "2026-08-15",
    "...": "..."
  },
  {
    "id": 2,
    "status": "completed",
    "created_at": "2026-08-16",
    "...": "..."
  }
]
```

### 4. الـ Frontend سيعرض:
```
م. │ التاريخ    │ السيارة  │ الوجهة   │ الكمية │ الحالة
───┼────────────┼─────────┼─────────┼───────┼────────
1  │ 2026-08-16 │ SAC-001 │ شارع ا │ 50.0  │🟠 مفتوحة
2  │ 2026-08-15 │ SAC-003 │ شارع ج │ 30.0  │🟠 مفتوحة
3  │ 2026-08-16 │ SAC-002 │ شارع ب │ 40.0  │🟢 مكتملة
```

---

**كود التعديل كامل وجاهز للنسخ!** ✅
