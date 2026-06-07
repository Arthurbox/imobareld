@echo off
echo 📡 Lancement du serveur Daphne pour IMOBARELD...
cd /d %~dp0
call .\venv\Scripts\activate
if %errorlevel% neq 0 (
    echo ❌ Erreur : Impossible d'activer l'environnement virtuel.
    pause
    exit /b %errorlevel%
)
echo 🚀 Démarrage de Daphne sur toutes les interfaces (port 8000)
daphne -b 0.0.0.0 -p 8000 core_backend.asgi:application
pause
