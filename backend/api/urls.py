from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UserViewSet, PropertyViewSet, VehicleViewSet, 
    CommentViewSet, ReviewViewSet, AnnouncementViewSet, AdViewSet,
    ReservationViewSet, DeliveryRequestViewSet,
    AdminStatsView, AdminUserListView, AdminVerificationView,
    approve_verification, reject_verification, revoke_verification,
    ImageUploadView,
    ChatListView, MessageListView,
    google_sign_in
)
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

# Utilisation du Router de Django Rest Framework pour gérer automatiquement les URLs des ViewSets
router = DefaultRouter()
# Enregistrement des ressources (CRUD automatique)
router.register(r'users', UserViewSet)
router.register(r'properties', PropertyViewSet)
router.register(r'vehicles', VehicleViewSet)
router.register(r'comments', CommentViewSet)
router.register(r'reviews', ReviewViewSet)
router.register(r'announcements', AnnouncementViewSet)
router.register(r'ads', AdViewSet)
router.register(r'reservations', ReservationViewSet)
router.register(r'delivery-requests', DeliveryRequestViewSet)
router.register(r'admin/users', AdminUserListView, basename='admin-users')
router.register(r'upload', ImageUploadView, basename='upload')

urlpatterns = [
    # Inclusion des routes générées par le router
    path('', include(router.urls)),
    
    # Endpoints spécifiques Admin (Stats et Vérifications)
    path('admin/stats/', AdminStatsView.as_view(), name='admin-stats'),
    path('admin/verifications/', AdminVerificationView.as_view(), name='admin-verifications'),
    path('admin/verifications/<int:pk>/approve/', approve_verification, name='approve-verification'),
    path('admin/verifications/<int:pk>/reject/', reject_verification, name='reject-verification'),
    path('admin/verifications/<int:pk>/revoke/', revoke_verification, name='revoke-verification'),

    # Endpoints pour le Chat
    path('chats/', ChatListView.as_view(), name='chat_list'),
    path('chats/<int:other_user_id>/', MessageListView.as_view(), name='chat_messages'),

    # Endpoint personnalisé pour la connexion Google
    path('auth/google/', google_sign_in, name='google_sign_in'),
    # Endpoints pour l'authentification JWT classique (Login et Refresh Token)
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
