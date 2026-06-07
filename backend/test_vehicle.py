import os
import django
import sys

# Setup Django atmosphere
sys.path.append('c:\\Users\\ASUS\\imobareld\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_backend.settings')
django.setup()

from api.models import User, Vehicle
from api.serializers import VehicleSerializer
from decimal import Decimal

def test_create_vehicle():
    print("Testing Vehicle Creation...")
    
    # Get a user (e.g., afrmd05@gmail.com)
    user = User.objects.filter(email='afrmd05@gmail.com').first()
    if not user:
        print("❌ User not found!")
        return
        
    data = {
        'companyName': 'Test Company',
        'model': 'Test Model',
        'city': 'Ouagadougou',
        'pricePerDay': '2500.00',
        'imageUrl': 'https://example.com/image.jpg',
        'description': 'Test Description',
        'owner': str(user.id)
    }
    
    serializer = VehicleSerializer(data=data)
    if serializer.is_valid():
        print("✅ Serializer is valid!")
        vehicle = serializer.save()
        print(f"✅ Vehicle created with ID: {vehicle.id}")
    else:
        print(f"❌ Serializer errors: {serializer.errors}")

if __name__ == "__main__":
    test_create_vehicle()
