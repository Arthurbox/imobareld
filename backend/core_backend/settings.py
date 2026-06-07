"""
Configuration du projet Django core_backend.
Les variables sensibles sont chargées depuis le fichier .env
via python-dotenv pour des raisons de sécurité.
"""

from pathlib import Path
import os
from dotenv import load_dotenv

# Chemin de base du projet
BASE_DIR = Path(__file__).resolve().parent.parent

# Chargement des variables d'environnement depuis .env
load_dotenv(BASE_DIR / '.env')

# ======================================================
# PARAMÈTRES DE SÉCURITÉ (chargés depuis .env)
# ======================================================
SECRET_KEY = os.getenv('SECRET_KEY', 'fallback-insecure-key-change-me')
DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost').split(',')

# ======================================================
# APPLICATIONS INSTALLÉES
# ======================================================
INSTALLED_APPS = [
    'daphne',  # Serveur ASGI pour WebSockets/Channels
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',  # 🟡 FIX: CORS pour Flutter Web
    'api',
]

# ======================================================
# MIDDLEWARES
# ======================================================
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # 🟡 FIX: CORS en premier
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'core_backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'core_backend.wsgi.application'
ASGI_APPLICATION = 'core_backend.asgi.application'

# ======================================================
# CHANNELS - Temps réel via Redis
# ======================================================
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            "hosts": [(
                os.getenv('REDIS_HOST', '127.0.0.1'),
                int(os.getenv('REDIS_PORT', 6379))
            )],
        },
    },
}

# ======================================================
# BASE DE DONNÉES PostgreSQL (chargée depuis .env)
# ======================================================
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'imobareld_db'),
        'USER': os.getenv('DB_USER', 'imobareld_admin'),
        'PASSWORD': os.getenv('DB_PASSWORD', ''),
        'HOST': os.getenv('DB_HOST', '127.0.0.1'),
        'PORT': os.getenv('DB_PORT', '5432'),
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'fr-fr'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# ======================================================
# DJANGO REST FRAMEWORK
# ======================================================
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ],
    # 🟡 FIX: Pagination globale pour éviter les réponses trop lourdes
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,  # 20 items par page par défaut
}

# ======================================================
# 🟡 FIX: CORS - Autorise Flutter Web et le frontend
# ======================================================
CORS_ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.getenv('CORS_ALLOWED_ORIGINS', 'http://localhost:3000').split(',')
]

# En développement, autoriser toutes les origines locales
if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True

CORS_ALLOW_CREDENTIALS = True

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]

# ======================================================
# FICHIERS STATIQUES ET MEDIA
# ======================================================
STATIC_URL = 'static/'
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

AUTH_USER_MODEL = 'api.User'

# Taille maximale des uploads (15 Mo pour images Base64)
DATA_UPLOAD_MAX_MEMORY_SIZE = 15728640
FILE_UPLOAD_MAX_MEMORY_SIZE = 15728640
