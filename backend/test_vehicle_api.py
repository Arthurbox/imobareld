import requests
import json

def test_api_create_vehicle():
    url = "http://localhost:8000/api/v1/vehicles/"
    
    # We need a token or we can rely on AllowAny if it's set
    # Since VehicleViewSet has permission_classes = [AllowAny], it should work without token
    
    data = {
        'companyName': 'API Test Company',
        'model': 'API Test Model',
        'city': 'Ouagadougou',
        'pricePerDay': 2500.0,
        'imageUrl': 'https://example.com/api_test.jpg',
        'description': 'Description from API test',
        'owner': '2'  # String ID
    }
    
    print(f"Sending request to {url}...")
    response = requests.post(url, json=data)
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")

if __name__ == "__main__":
    test_api_create_vehicle()
