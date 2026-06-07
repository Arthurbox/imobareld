import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_backend.settings')
django.setup()
from django.db import connection
try:
    with connection.cursor() as cursor:
        cursor.execute('DROP SCHEMA public CASCADE; CREATE SCHEMA public;')
        cursor.execute('GRANT ALL ON SCHEMA public TO postgres;')
        cursor.execute('GRANT ALL ON SCHEMA public TO public;')
    print("DB reset SUCCESS")
except Exception as e:
    print("Error:", e)
