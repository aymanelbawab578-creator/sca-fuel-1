#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re

# قراءة الملف الأصلي
with open('backup_neon_before_supabase.sql', 'r', encoding='utf-8') as f:
    content = f.read()

# عداد لأوامر COPY
copy_count = 0

# تحويل أوامر COPY إلى INSERT INTO
def convert_copy_to_insert(content):
    global copy_count
    
    # البحث عن جميع أوامر COPY
    pattern = r'COPY\s+public\.(\w+)\s*\((.*?)\)\s+FROM\s+stdin;(.*?)^\\\.'
    
    def replace_func(match):
        global copy_count
        copy_count += 1
        
        table_name = match.group(1)
        columns_str = match.group(2)
        data_str = match.group(3)
        
        # تنظيف أسماء الأعمدة
        columns = [col.strip() for col in columns_str.split(',')]
        
        # تقسيم البيانات على أسطر
        lines = data_str.strip().split('\n')
        
        # حذف السطر الفارغ الأخير إن وجد
        if lines and not lines[-1].strip():
            lines = lines[:-1]
        
        if not lines or not lines[0].strip():
            # لا توجد بيانات
            return match.group(0)
        
        # بناء عبارات INSERT
        insert_statements = []
        
        for line in lines:
            if not line.strip():
                continue
            
            # تقسيم السطر على علامات التبويب
            values = line.split('\t')
            
            if len(values) != len(columns):
                print(f"تحذير: عدد الأعمدة غير متطابق للجدول {table_name}")
                continue
            
            # تحويل القيم
            processed_values = []
            for i, val in enumerate(values):
                if val == '\\N':
                    # NULL
                    processed_values.append('NULL')
                else:
                    # تجنب الاقتباسات الموجودة في البيانات
                    val = val.replace("'", "''")
                    # اقتباس القيم
                    processed_values.append(f"'{val}'")
            
            # بناء عبارة INSERT
            cols = ', '.join(columns)
            vals = ', '.join(processed_values)
            insert_stmt = f"INSERT INTO public.{table_name} ({cols}) VALUES ({vals});"
            insert_statements.append(insert_stmt)
        
        # دمج جميع عبارات INSERT
        if insert_statements:
            result = '\n'.join(insert_statements)
            return result
        else:
            return match.group(0)
    
    # استبدال جميع أوامر COPY
    new_content = re.sub(pattern, replace_func, content, flags=re.MULTILINE | re.DOTALL)
    
    return new_content

# تحويل الملف
converted_content = convert_copy_to_insert(content)

# حفظ الملف الجديد
with open('backup_supabase.sql', 'w', encoding='utf-8') as f:
    f.write(converted_content)

print(f"✓ تم تحويل الملف بنجاح!")
print(f"✓ عدد أوامر COPY التي تم تحويلها: {copy_count}")
print(f"✓ تم حفظ الملف الجديد: backup_supabase.sql")
