import os
import base64
import uuid
from django.core.management.base import BaseCommand
from django.core.files.base import ContentFile
from django.conf import settings
from api.models import User, Property, Vehicle, Comment, Review, Ad

class Command(BaseCommand):
    help = 'Migrate Base64 images in database to physical files in MEDIA_ROOT'

    def handle(self, *args, **options):
        self.migrate_users()
        self.migrate_properties()
        self.migrate_vehicles()
        self.migrate_ads()
        self.migrate_comments_reviews()
        self.stdout.write(self.style.SUCCESS('Successfully migrated all Base64 images to files.'))

    def save_base64_as_file(self, base64_str, folder):
        if not base64_str or not isinstance(base64_str, str) or base64_str.startswith('http') or base64_str.startswith('/media/'):
            return None
        
        try:
            if ';base64,' in base64_str:
                format, imgstr = base64_str.split(';base64,')
                ext = format.split('/')[-1]
            else:
                imgstr = base64_str
                ext = 'jpg' # Default

            data = ContentFile(base64.b64decode(imgstr))
            file_name = f"{uuid.uuid4()}.{ext}"
            
            # Ensure folder exists
            full_folder_path = os.path.join(settings.MEDIA_ROOT, folder)
            os.makedirs(full_folder_path, exist_ok=True)
            
            relative_path = os.path.join(folder, file_name)
            full_path = os.path.join(settings.MEDIA_ROOT, relative_path)
            
            with open(full_path, 'wb') as f:
                f.write(data.read())
            
            return f"/media/{relative_path.replace('\\', '/')}"
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Error converting base64: {e}'))
            return None

    def migrate_users(self):
        self.stdout.write('Migrating User profiles...')
        for user in User.objects.exclude(profilePicture__isnull=True).exclude(profilePicture=''):
            new_path = self.save_base64_as_file(user.profilePicture, 'profiles')
            if new_path:
                user.profilePicture = new_path
                user.save()

    def migrate_properties(self):
        self.stdout.write('Migrating Properties...')
        for prop in Property.objects.all():
            updated = False
            new_images = []
            for img in prop.images:
                new_path = self.save_base64_as_file(img, 'properties')
                if new_path:
                    new_images.append(new_path)
                    updated = True
                else:
                    new_images.append(img)
            
            if updated:
                prop.images = new_images
                prop.save()
            
            if prop.videoBase64:
                new_video = self.save_base64_as_file(prop.videoBase64, 'videos')
                if new_video:
                    prop.videoBase64 = new_video
                    prop.save()

    def migrate_vehicles(self):
        self.stdout.write('Migrating Vehicles...')
        for vehicle in Vehicle.objects.exclude(imageUrl=''):
            new_path = self.save_base64_as_file(vehicle.imageUrl, 'vehicles')
            if new_path:
                vehicle.imageUrl = new_path
                vehicle.save()

    def migrate_ads(self):
        self.stdout.write('Migrating Ads...')
        for ad in Ad.objects.all():
            new_path = self.save_base64_as_file(ad.imageUrl, 'ads')
            if new_path:
                ad.imageUrl = new_path
                ad.save()

    def migrate_comments_reviews(self):
        self.stdout.write('Migrating Comments and Reviews...')
        for comment in Comment.objects.exclude(authorProfilePicture__isnull=True).exclude(authorProfilePicture=''):
            new_path = self.save_base64_as_file(comment.authorProfilePicture, 'profiles')
            if new_path:
                comment.authorProfilePicture = new_path
                comment.save()
        
        for review in Review.objects.exclude(userProfilePicture__isnull=True).exclude(userProfilePicture=''):
            new_path = self.save_base64_as_file(review.userProfilePicture, 'profiles')
            if new_path:
                review.userProfilePicture = new_path
                review.save()
