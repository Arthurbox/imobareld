from django.db import models
from django.contrib.auth.models import AbstractUser

# Modèle Utilisateur personnalisé étendant le modèle AbstractUser de Django
class User(AbstractUser):
    # Choix pour le type d'utilisateur (Locataire ou Propriétaire)
    USER_TYPE_CHOICES = (
        ('locataire', 'Locataire'),
        ('propriétaire', 'Propriétaire'),
    )
    # Rôles au sein de la plateforme
    ROLE_CHOICES = (
        ('user', 'User'),
        ('admin', 'Admin'),
    )
    
    # Utilisation de l'email comme identifiant unique au lieu du username
    email = models.EmailField(unique=True)
    # Type d'utilisateur choisi lors de l'inscription
    userType = models.CharField(max_length=20, choices=USER_TYPE_CHOICES, default='locataire')
    # Rôle (standard ou administrateur)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='user')
    # Image de profil (stockée en Base64 pour la compatibilité avec l'ancien système Firebase)
    profilePicture = models.TextField(null=True, blank=True)
    # Numéro de téléphone
    phone = models.CharField(max_length=30, null=True, blank=True)
    # État de vérification de l'utilisateur (ex: 'verified', 'pending', 'none')
    verificationStatus = models.CharField(max_length=20, default='none')
    # Liste des documents de vérification stockés sous forme de JSON
    verificationDocuments = models.JSONField(default=list, blank=True)
    # Date et heure de la dernière lecture des annonces globales
    lastReadAnnouncement = models.DateTimeField(null=True, blank=True)
    # Date et heure de la dernière consultation des propriétés par l'utilisateur
    lastReadProperties = models.DateTimeField(null=True, blank=True)

    # Configuration pour utiliser l'email pour l'authentification
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    def save(self, *args, **kwargs):
        # Assurer que le username est défini sur l'email si absent
        if not self.username and self.email:
            self.username = self.email
        super().save(*args, **kwargs)

    def __str__(self):
        return self.email

# Modèle représentant une Propriété Immobilère (Maison, Terrain, Apprtement, etc.)
class Property(models.Model):
    # Propriétaire associé (lié au modèle User)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='properties')
    # Titre de l'annonce
    title = models.CharField(max_length=255)
    # Description détaillée du bien
    description = models.TextField(blank=True, null=True)
    # Catégorie (ex: Maison, Bureau, Appartement)
    category = models.CharField(max_length=100)
    # Prix du bien ou du loyer
    price = models.DecimalField(max_digits=12, decimal_places=2)
    # Ville où se situe le bien
    city = models.CharField(max_length=100, default='Ouagadougou')
    # Quartier ou zone spécifique
    quartier = models.CharField(max_length=150)
    # Liste des URLs ou formats des images du bien (stockées en JSON)
    images = models.JSONField(default=list)
    # Nombre de pièces
    pieces = models.IntegerField(default=0)
    # Date de création de l'annonce
    createdAt = models.DateTimeField(auto_now_add=True)
    # Coordonnées géographiques pour la carte
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    # Nombre total de likes reçus
    likesCount = models.IntegerField(default=0)
    # Utilisateurs ayant aimé ce bien
    likedBy = models.ManyToManyField(User, related_name='liked_properties', blank=True)
    # Vidéo de présentation (URL)
    videoUrl = models.TextField(null=True, blank=True)
    # Indique si le propriétaire est vérifié par le système
    isOwnerVerified = models.BooleanField(default=False)
    # Durée du prix (ex: par mois, par jour, prix total)
    priceDuration = models.CharField(max_length=50, default='mois')
    # Liste des équipements (ex: Wifi, Parking, Climatisation)
    amenities = models.JSONField(default=list)
    # Indique si le bien est certifié par l'équipe IMOBARELD
    isCertified = models.BooleanField(default=False)
    # Note moyenne laissée par les utilisateurs
    averageRating = models.FloatField(default=0.0)
    # Nombre total d'avis/commentaires
    reviewCount = models.IntegerField(default=0)
    # Type de transaction (ex: Location, Vente)
    transactionType = models.CharField(max_length=50, default='Location')
    # Avance sur loyer en mois
    rentAdvanceMonths = models.IntegerField(default=0)
    # Caution en mois
    securityDepositMonths = models.IntegerField(default=0)
    # Indique si l'annonce est mise en avant (Boostée)
    isBoosted = models.BooleanField(default=False)
    # Date d'expiration du boost
    boostExpiryDate = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return self.title

# Modèle représentant un Véhicule (Location de voiture)
class Vehicle(models.Model):
    # Propriétaire ou agence de location associée
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='vehicles')
    # Nom de l'agence ou de la marque
    companyName = models.CharField(max_length=255)
    # Modèle du véhicule
    model = models.CharField(max_length=255)
    # Ville de disponibilité
    city = models.CharField(max_length=100, default='Ouagadougou')
    # Prix de location par jour
    pricePerDay = models.DecimalField(max_digits=10, decimal_places=2)
    # URL de l'image principale
    imageUrl = models.TextField(blank=True, null=True)
    # Description technique du véhicule
    description = models.TextField(blank=True, null=True)
    # Date d'ajout du véhicule sur la plateforme
    createdAt = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.companyName} {self.model}"

# Modèle pour les Commentaires sur les propriétés
class Comment(models.Model):
    # Propriété concernée
    property = models.ForeignKey(Property, on_delete=models.CASCADE, related_name='comments')
    # Auteur du commentaire
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    # Nom de l'auteur (pour affichage rapide comme dans Firebase)
    authorName = models.CharField(max_length=255)
    # Contenu du commentaire
    content = models.TextField()
    # Date de création
    createdAt = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Comment by {self.authorName} on {self.property.title}"

# Modèle pour les Avis et Notes sur les propriétés
class Review(models.Model):
    # Propriété concernée
    property = models.ForeignKey(Property, on_delete=models.CASCADE, related_name='reviews')
    # Utilisateur ayant laissé l'avis
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    # Nom de l'utilisateur
    userName = models.CharField(max_length=255)
    # Note (sur 5)
    rating = models.FloatField()
    # Commentaire associé à la note
    comment = models.TextField()
    # Date de création
    createdAt = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Review ({self.rating}/5) by {self.userName}"

# Modèle pour les Annonces Globales (Flux d'actualité)
class Announcement(models.Model):
    # Auteur de l'annonce (souvent un admin ou un compte officiel)
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    # Nom de l'auteur
    authorName = models.CharField(max_length=255)
    # Contenu de l'annonce
    content = models.TextField()
    # Date de création
    createdAt = models.DateTimeField(auto_now_add=True)
    
    # Champs pour la gestion des réponses
    replyToId = models.IntegerField(null=True, blank=True)
    replyToContent = models.TextField(null=True, blank=True)
    replyToAuthorName = models.CharField(max_length=255, null=True, blank=True)

    def __str__(self):
        return f"Announcement by {self.authorName}: {self.content[:30]}..."

# Modèle pour les Messages Instantanés (Chat)
class Message(models.Model):
    # Expéditeur du message
    sender = models.ForeignKey(User, related_name='sent_messages', on_delete=models.CASCADE)
    # Destinataire du message
    receiver = models.ForeignKey(User, related_name='received_messages', on_delete=models.CASCADE)
    # Contenu du message
    message = models.TextField()
    # Date et heure d'envoi
    timestamp = models.DateTimeField(auto_now_add=True)
    # Indicateur de lecture
    isRead = models.BooleanField(default=False)

    class Meta:
        ordering = ['timestamp']

    def __str__(self):
        return f"Message from {self.sender.email} to {self.receiver.email} at {self.timestamp}"

# Modèle pour les Publicités (Ads)
class Ad(models.Model):
    # Image ou Vidéo (Base64)
    imageUrl = models.TextField()
    # Lien de redirection optionnel
    targetUrl = models.URLField(max_length=500, null=True, blank=True)
    # Priorité d'affichage (plus haut = premier)
    priority = models.IntegerField(default=0)
    # État d'activation
    isActive = models.BooleanField(default=True)
    # Type de contenu ('image' ou 'video')
    type = models.CharField(max_length=20, default='image')
    # Date de création
    createdAt = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Ad {self.id} ({self.type})"

# Modèle pour les Réservations de Véhicules
class Reservation(models.Model):
    STATUS_CHOICES = (
        ('pending', 'En attente'),
        ('accepted', 'Acceptée'),
        ('rejected', 'Refusée'),
    )
    
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='reservations')
    vehicleModel = models.CharField(max_length=255)
    vehicleCompanyName = models.CharField(max_length=255)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='owner_reservations')
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_reservations')
    userName = models.CharField(max_length=255)
    userEmail = models.EmailField()
    userPhone = models.CharField(max_length=30, null=True, blank=True)
    
    numberOfDays = models.IntegerField(default=1)
    withDriver = models.BooleanField(default=False)
    totalPrice = models.DecimalField(max_digits=12, decimal_places=2)
    
    # Documents de réservation (URLs)
    cnibImage = models.TextField(null=True, blank=True)
    cnibBackImage = models.TextField(null=True, blank=True)
    licenseImage = models.TextField(null=True, blank=True)
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    createdAt = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Reservation {self.id} for {self.vehicleModel} by {self.userName}"

# Modèle pour les Demandes de Livraison
class DeliveryRequest(models.Model):
    STATUS_CHOICES = (
        ('pending', 'En attente'),
        ('accepted', 'Acceptée'),
        ('completed', 'Terminée'),
        ('cancelled', 'Annulée'),
    )
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='delivery_requests')
    serviceType = models.CharField(max_length=100) # Ex: Petit colis, Meubles, etc.
    pickupAddress = models.CharField(max_length=255)
    destinationAddress = models.CharField(max_length=255)
    description = models.TextField()
    contactPhone = models.CharField(max_length=30)
    city = models.CharField(max_length=100, default='Ouagadougou')
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    createdAt = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Delivery {self.id} ({self.serviceType}) by {self.user.email}"
