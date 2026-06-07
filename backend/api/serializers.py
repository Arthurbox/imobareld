from rest_framework import serializers
from .models import User, Property, Vehicle, Comment, Review, Announcement, Message, Ad, Reservation, DeliveryRequest

# Sérialiseur pour le modèle Ad (Publicités)
class AdSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ad
        fields = '__all__'

# Sérialiseur pour le modèle User

# Sérialiseur pour le modèle User
# Gère la conversion des données utilisateur entre le format JSON et les objets Python
class UserSerializer(serializers.ModelSerializer):
    # Mapping du champ 'name' de l'API vers 'first_name' du modèle Django
    name = serializers.CharField(source='first_name', allow_blank=True, required=False)
    # Champs de date de lecture avec formatage spécifique pour le frontend
    lastReadAnnouncement = serializers.DateTimeField(required=False, allow_null=True, style={'input_type': 'text'})
    lastReadProperties = serializers.DateTimeField(required=False, allow_null=True, style={'input_type': 'text'})
    # Map date_joined (Django) vers createdAt (Flutter)
    createdAt = serializers.DateTimeField(source='date_joined', read_only=True)
    
    class Meta:
        model = User
        # Liste exhaustive des champs à inclure dans les réponses API
        fields = [
            'id', 'email', 'name', 'userType', 'role', 'profilePicture', 
            'phone', 'verificationStatus', 'verificationDocuments', 
            'lastReadAnnouncement', 'lastReadProperties', 'password', 'createdAt'
        ]
        # Le mot de passe est configuré en 'write_only' pour ne jamais être renvoyé dans les réponses
        extra_kwargs = {'password': {'write_only': True}}
    
    # Surcharge de la méthode de création pour hacher le mot de passe
    def create(self, validated_data):
        password = validated_data.pop('password', None)
        user = super().create(validated_data)
        if password:
            user.set_password(password) # Hachage sécurisé du mot de passe
            user.save()
        return user

# Sérialiseur pour le modèle Property (Biens immobiliers)
class PropertySerializer(serializers.ModelSerializer):
    # Champ de date d'expiration du boost
    boostExpiryDate = serializers.DateTimeField(required=False, allow_null=True, style={'input_type': 'text'})
    # Détermine si l'utilisateur actuel a aimé ce bien
    isLiked = serializers.SerializerMethodField()
    
    class Meta:
        model = Property
        # Inclure tous les champs du modèle
        fields = '__all__'

    def get_isLiked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likedBy.filter(id=request.user.id).exists()
        return False

# Sérialiseur pour le modèle Vehicle (Location de voitures)
class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        # Inclure tous les champs du modèle
        fields = '__all__'

# Sérialiseur pour les Commentaires
class CommentSerializer(serializers.ModelSerializer):
    authorProfilePicture = serializers.ReadOnlyField(source='author.profilePicture')
    propertyId = serializers.ReadOnlyField(source='property.id')
    authorId = serializers.ReadOnlyField(source='author.id')

    class Meta:
        model = Comment
        fields = ['id', 'propertyId', 'authorId', 'authorName', 'authorProfilePicture', 'content', 'createdAt', 'property', 'author']

# Sérialiseur pour les Avis
class ReviewSerializer(serializers.ModelSerializer):
    userProfilePicture = serializers.ReadOnlyField(source='user.profilePicture')
    propertyId = serializers.ReadOnlyField(source='property.id')
    userId = serializers.ReadOnlyField(source='user.id')

    class Meta:
        model = Review
        fields = ['id', 'propertyId', 'userId', 'userName', 'userProfilePicture', 'rating', 'comment', 'createdAt', 'property', 'user']

# Sérialiseur pour les Annonces Globales
class AnnouncementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Announcement
        fields = '__all__'

# Sérialiseur pour les Messages de Chat
class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = '__all__'

# Sérialiseur pour les Réservations
class ReservationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Reservation
        fields = '__all__'

# Sérialiseur pour les Demandes de Livraison
class DeliveryRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryRequest
        fields = '__all__'
