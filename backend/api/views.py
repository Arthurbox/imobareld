from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework_simplejwt.tokens import RefreshToken
from django.conf import settings
from .models import User, Property, Vehicle, Comment, Review, Announcement, Message, Ad, Reservation, DeliveryRequest
from .serializers import (
    UserSerializer, PropertySerializer, VehicleSerializer, 
    CommentSerializer, ReviewSerializer, AnnouncementSerializer, MessageSerializer,
    AdSerializer, ReservationSerializer, DeliveryRequestSerializer
)
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
import os
import uuid

# ViewSet pour la gestion des utilisateurs
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

    def perform_create(self, serializer):
        # 🟠 FIX: Promotion admin supprimée. Utiliser `python manage.py createsuperuser`
        # ou le panel Django Admin pour promouvoir un utilisateur admin.
        user = serializer.save(role='user', is_staff=False, is_superuser=False)

        # Hashage du mot de passe
        password = self.request.data.get('password')
        if password:
            user.set_password(password)
            user.save()

    # Définition des permissions selon l'action
    def get_permissions(self):
        if self.action == 'create':
            # Autoriser tout le monde à créer un compte (Inscription)
            return [AllowAny()]
        # Authentification requise pour les autres actions
        return [IsAuthenticated()]

    # Action personnalisée pour récupérer ou mettre à jour le profil de l'utilisateur connecté
    @action(detail=False, methods=['get', 'patch', 'put'])
    def me(self, request):
        user = request.user
        if request.method in ['PATCH', 'PUT']:
            # Mise à jour partielle ou complète
            serializer = self.get_serializer(user, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        # Par défaut (GET)
        serializer = self.get_serializer(user)
        return Response(serializer.data)

# Vue pour gérer la connexion via Google (Google Sign-In)
@api_view(['POST'])
@permission_classes([AllowAny])
def google_sign_in(request):
    # Récupération du jeton idToken envoyé par le frontend Flutter
    token = request.data.get('idToken')
    # Type d'utilisateur (locataire par défaut)
    user_type = request.data.get('userType', 'locataire')
    
    if not token:
        return Response({'error': 'idToken is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Vérification du jeton avec les serveurs de Google
        # Note: id_token.verify_oauth2_token vérifie la signature et l'expiration
        id_info = id_token.verify_oauth2_token(token, google_requests.Request())
        
        # Extraction des informations de l'utilisateur depuis le jeton Google
        email = id_info.get('email')
        name = id_info.get('name', '')
        picture = id_info.get('picture', '')
        
        # Récupérer l'utilisateur existant ou en créer un nouveau basé sur l'email
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'first_name': name,
                'userType': user_type,
                'profilePicture': picture,
                'role': 'user',
            }
        )

        # Mettre à jour la photo de profil si c'est un utilisateur existant via Google
        if not created and picture and not user.profilePicture:
            user.profilePicture = picture
            user.save(update_fields=['profilePicture'])

        # 🟠 FIX: Promotion admin supprimée.
        # Gérer les rôles via `python manage.py createsuperuser` ou le panel Django Admin.

        # Génération manuelle des jetons JWT (Simple JWT) pour l'utilisateur
        refresh = RefreshToken.for_user(user)
        
        # Retourner les tokens et les données utilisateur au frontend
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': UserSerializer(user).data
        })
        
    except ValueError:
        # Jeton invalide ou expiré
        return Response({'error': 'Invalid token'}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        # Autre erreur serveur
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# ViewSet pour la gestion des Biens Immobiliers
class PropertyViewSet(viewsets.ModelViewSet):
    """
    Vue pour gérer les opérations CRUD sur les propriétés.
    Inclut une logique personnalisée de filtrage (catégorie, ville, prix, recherche).
    """
    queryset = Property.objects.all().order_by('-createdAt')
    serializer_class = PropertySerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        # Récupération du queryset de base (toutes les propriétés triées par date)
        queryset = super().get_queryset()
        
        # Récupération des paramètres de filtrage depuis l'URL (query params)
        category = self.request.query_params.get('category')
        city = self.request.query_params.get('city')
        quartier = self.request.query_params.get('quartier')
        min_price = self.request.query_params.get('minPrice')
        max_price = self.request.query_params.get('maxPrice')
        min_pieces = self.request.query_params.get('minPieces')
        search_query = self.request.query_params.get('search')
        owner_id = self.request.query_params.get('ownerId')

        # Application progressive des filtres si les paramètres sont fournis
        if category and category not in ['Toutes', 'Tous']:
            queryset = queryset.filter(category=category)
        if city and city not in ['Toutes les villes', 'Toutes']:
            queryset = queryset.filter(city=city)
        if quartier and quartier not in ['Tous']:
            queryset = queryset.filter(quartier=quartier)
        if min_price:
            queryset = queryset.filter(price__gte=min_price)
        if max_price:
            queryset = queryset.filter(price__lte=max_price)
        if min_pieces:
            queryset = queryset.filter(pieces__gte=min_pieces)
        if owner_id:
            queryset = queryset.filter(owner_id=owner_id)
            
        # Logique de recherche textuelle (titre, description ou quartier)
        if search_query:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(title__icontains=search_query) | 
                Q(description__icontains=search_query) |
                Q(quartier__icontains=search_query)
            )

        return queryset
        
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def toggle_like(self, request, pk=None):
        """
        Action pour ajouter ou retirer un 'Like' sur un bien.
        """
        property = self.get_object()
        user = request.user
        
        if property.likedBy.filter(id=user.id).exists():
            # Déjà aimé -> On retire le like
            property.likedBy.remove(user)
            is_liked = False
        else:
            # Pas encore aimé -> On ajoute le like
            property.likedBy.add(user)
            is_liked = True
            
        # Mise à jour du compteur pour des performances de lecture optimales
        property.likesCount = property.likedBy.count()
        property.save()
        
        return Response({
            'is_liked': is_liked,
            'likes_count': property.likesCount
        })

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def favorites(self, request):
        """
        Action pour récupérer tous les biens likés par l'utilisateur actuel.
        """
        user = request.user
        queryset = Property.objects.filter(likedBy=user).order_by('-createdAt')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

# ViewSet pour la gestion des Véhicules de location
class VehicleViewSet(viewsets.ModelViewSet):
    """
    Vue pour gérer les opérations CRUD sur les véhicules.
    """
    queryset = Vehicle.objects.all().order_by('-createdAt')
    serializer_class = VehicleSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        print(f"🔥 Vehicle Create Request Data: {request.data}")
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print(f"❌ Vehicle Validation Error: {serializer.errors}")
        return super().create(request, *args, **kwargs)

    def get_queryset(self):
        queryset = super().get_queryset()
        
        city = self.request.query_params.get('city')
        owner_id = self.request.query_params.get('ownerId')

        if city and city not in ['Toutes les villes', 'Toutes']:
            queryset = queryset.filter(city=city)
        if owner_id:
            queryset = queryset.filter(owner_id=owner_id)

        return queryset

# ViewSet pour la gestion des Publicités
class AdViewSet(viewsets.ModelViewSet):
    """
    Vue pour gérer les publicités (images et vidéos) affichées sur la plateforme.
    """
    queryset = Ad.objects.values('id', 'imageUrl', 'targetUrl', 'priority', 'isActive', 'type', 'createdAt').order_by('-priority', '-createdAt')
    serializer_class = AdSerializer
    permission_classes = [AllowAny] # Permettre à tout le monde de lire les pubs actives

    def get_queryset(self):
        # On peut imaginer filtrer ici les publicités actives pour le frontend public
        # mais le dashboard admin a besoin de voir toutes les publicités.
        return Ad.objects.all().order_by('-priority', '-createdAt')

# ViewSet pour les Commentaires
class CommentViewSet(viewsets.ModelViewSet):
    queryset = Comment.objects.all().order_by('-createdAt')
    serializer_class = CommentSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = super().get_queryset()
        property_id = self.request.query_params.get('property_id')
        if property_id:
            queryset = queryset.filter(property_id=property_id)
        return queryset

# ViewSet pour les Avis
class ReviewViewSet(viewsets.ModelViewSet):
    queryset = Review.objects.all().order_by('-createdAt')
    serializer_class = ReviewSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = super().get_queryset()
        property_id = self.request.query_params.get('property_id')
        if property_id:
            queryset = queryset.filter(property_id=property_id)
        return queryset

# ViewSet pour les Annonces Globales
class AnnouncementViewSet(viewsets.ModelViewSet):
    queryset = Announcement.objects.all().order_by('-createdAt')
    serializer_class = AnnouncementSerializer
    permission_classes = [AllowAny]


from django.db.models import Q
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

class ChatListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        # Trouver tous les messages où l'utilisateur est expéditeur ou destinataire
        messages = Message.objects.filter(Q(sender=user) | Q(receiver=user)).order_by('-timestamp')
        
        # Grouper les messages par conversation (autre utilisateur)
        conversations = {}
        for msg in messages:
            other_user = msg.receiver if msg.sender == user else msg.sender
            other_id = str(other_user.id)
            if other_id not in conversations:
                conversations[other_id] = {
                    'other_user_id': other_id,
                    'users': [str(user.id), other_id],
                    'lastMessage': msg.message,
                    'lastTimestamp': msg.timestamp.isoformat(),
                    'lastSenderId': str(msg.sender.id),
                }
        
        # Convertir en liste
        chat_list = list(conversations.values())
        return Response(chat_list)

class MessageListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, other_user_id):
        user = request.user
        messages = Message.objects.filter(
            (Q(sender=user) & Q(receiver_id=other_user_id)) |
            (Q(sender_id=other_user_id) & Q(receiver=user))
        ).order_by('-timestamp') # Du plus récent au plus ancien (comme Flutter ListView.builder reverse=True)
        
        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)

import os
import uuid
from rest_framework.parsers import MultiPartParser, FormParser
from django.conf import settings

# Vue pour le téléchargement d'images (Multipart)
class ImageUploadView(viewsets.ViewSet):
    """
    Vue pour télécharger une ou plusieurs images et retourner leurs URLs.
    """
    parser_classes = (MultiPartParser, FormParser)
    permission_classes = [AllowAny]

    def create(self, request):
        # Supporte 'images' et 'images[]' pour la compatibilité avec divers clients
        images = request.FILES.getlist('images') or request.FILES.getlist('images[]')
        
        if not images:
            # Essayer de voir s'il y a un champ 'image' (singulier)
            single_image = request.FILES.get('image')
            if single_image:
                images = [single_image]

        if not images:
            print(f"DEBUG: Aucun fichier reçu dans request.FILES. Keys: {request.FILES.keys()}")
            return Response({'error': 'Aucune image fournie'}, status=status.HTTP_400_BAD_REQUEST)

        print(f"DEBUG: Réception de {len(images)} images")

        urls = []
        # Créer le dossier media si non existant
        media_path = os.path.join(settings.MEDIA_ROOT, 'uploads')
        if not os.path.exists(media_path):
            os.makedirs(media_path)

        for img in images:
            # Générer un nom de fichier unique
            ext = os.path.splitext(img.name)[1]
            filename = f"{uuid.uuid4()}{ext}"
            file_path = os.path.join(media_path, filename)

            # Sauvegarder le fichier
            with open(file_path, 'wb+') as destination:
                for chunk in img.chunks():
                    destination.write(chunk)
            
            # Ajouter l'URL relative
            # L'URL doit être accessible via MEDIA_URL
            urls.append(f"{settings.MEDIA_URL}uploads/{filename}")

        return Response({'urls': urls, 'message': 'Images téléchargées avec succès'}, status=status.HTTP_201_CREATED)

# ViewSet pour les Réservations de véhicules
class ReservationViewSet(viewsets.ModelViewSet):
    queryset = Reservation.objects.all().order_by('-createdAt')
    serializer_class = ReservationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        owner_id = self.request.query_params.get('ownerId')
        user_id = self.request.query_params.get('userId')
        if owner_id:
            queryset = queryset.filter(owner_id=owner_id)
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        return queryset

# ViewSet pour les Demandes de livraison
class DeliveryRequestViewSet(viewsets.ModelViewSet):
    queryset = DeliveryRequest.objects.all().order_by('-createdAt')
    serializer_class = DeliveryRequestSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        user_id = self.request.query_params.get('userId')
        city = self.request.query_params.get('city')
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        if city:
            queryset = queryset.filter(city=city)
        return queryset

# Vues spécifiques pour le Dashboard Admin
class AdminStatsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Vérification insensible à la casse
        if str(request.user.role).lower() != 'admin':
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        
        data = {
            'totalUsers': User.objects.count(),
            'owners': User.objects.filter(userType='propriétaire').count(),
            'tenants': User.objects.filter(userType='locataire').count(),
            'verified': User.objects.filter(verificationStatus='verified').count(),
            'pending': User.objects.filter(verificationStatus='pending').count(),
            'totalProperties': Property.objects.count(),
            'totalVehicles': Vehicle.objects.count(),
            'totalDeliveryRequests': DeliveryRequest.objects.count(),
        }
        return Response(data)

class AdminUserListView(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get_queryset(self):
        if self.request.user.role != 'admin':
            return User.objects.none()
        
        queryset = User.objects.all().order_by('-date_joined')
        query = self.request.query_params.get('q')
        if query:
            queryset = queryset.filter(
                Q(email__icontains=query) | Q(first_name__icontains=query)
            )
        return queryset

    def perform_update(self, serializer):
        # Mettre à jour is_staff et is_superuser en fonction du rôle (nommé admin par le Super Admin)
        user = serializer.save()
        if user.role == 'admin':
            user.is_staff = True
            user.is_superuser = True
        else:
            user.is_staff = False
            user.is_superuser = False
        user.save(update_fields=['is_staff', 'is_superuser'])

class AdminVerificationView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != 'admin':
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        
        # Liste des dossiers en attente ou vérifiés récemment
        users = User.objects.filter(
            Q(verificationStatus='pending') | Q(verificationStatus='verified')
        ).order_by('-date_joined')
        
        serializer = UserSerializer(users, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        if request.user.role != 'admin':
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        user = User.objects.get(pk=pk)
        user.verificationStatus = 'verified'
        user.save()
        return Response({'status': 'verified'})

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        if request.user.role != 'admin':
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        user = User.objects.get(pk=pk)
        user.verificationStatus = 'rejected'
        user.save()
        return Response({'status': 'rejected'})

    @action(detail=True, methods=['post'])
    def revoke(self, request, pk=None):
        if request.user.role != 'admin':
            return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
        user = User.objects.get(pk=pk)
        user.verificationStatus = 'none'
        user.save()
        return Response({'status': 'none'})

# Note: Pour gérer les actions approve/reject/revoke facilement, 
# il est préférable d'utiliser des fonctions @api_view ou d'étendre AdminVerificationView
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def approve_verification(request, pk):
    if request.user.role != 'admin':
        return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
    try:
        user = User.objects.get(pk=pk)
        user.verificationStatus = 'verified'
        user.save()
        return Response({'status': 'verified'})
    except User.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def reject_verification(request, pk):
    if request.user.role != 'admin':
        return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
    try:
        user = User.objects.get(pk=pk)
        user.verificationStatus = 'rejected'
        user.save()
        return Response({'status': 'rejected'})
    except User.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def revoke_verification(request, pk):
    if request.user.role != 'admin':
        return Response({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)
    try:
        user = User.objects.get(pk=pk)
        user.verificationStatus = 'none'
        user.save()
        return Response({'status': 'none'})
    except User.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
