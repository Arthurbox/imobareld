"""
fix_icon_center.py
------------------
Recentre parfaitement le logo IMOBARELD dans son canvas
pour que l'icône de l'app soit bien centrée visuellement.

Problème détecté : le logo (fond noir + design) est décalé vers le haut,
laissant un excès d'espace blanc en bas du canvas source.

Ce script :
  1. Détecte la boîte englobante réelle du logo (pixels non-blancs)
  2. Recadre proprement
  3. Recentre avec une marge uniforme sur les 4 côtés (padding de 8%)
  4. Sauvegarde sur un canvas 1024x1024 transparent
"""

from PIL import Image
import shutil
import os

def fix_icon_center():
    source_path = r'assets\splash\logo.png'
    backup_path = r'assets\splash\logo_backup.png'

    # --- Étape 1 : Sauvegarde du logo original ---
    if not os.path.exists(backup_path):
        shutil.copy2(source_path, backup_path)
        print(f"✅ Backup créé : {backup_path}")
    else:
        print(f"ℹ️  Backup existant conservé : {backup_path}")

    # --- Étape 2 : Ouvrir l'image ---
    im = Image.open(source_path).convert("RGBA")
    print(f"📐 Taille originale : {im.size}")

    # --- Étape 3 : Détecter les pixels non-blancs et non-transparents ---
    # On considère "vide" : transparent (alpha < 20) OU blanc pur (r,g,b > 240)
    data = im.getdata()
    mask_pixels = []
    for r, g, b, a in data:
        is_transparent = a < 20
        is_white = r > 240 and g > 240 and b > 240
        if is_transparent or is_white:
            mask_pixels.append(0)   # pixel vide
        else:
            mask_pixels.append(255) # pixel du logo

    mask_im = Image.new("L", im.size)
    mask_im.putdata(mask_pixels)
    bbox = mask_im.getbbox()

    if not bbox:
        print("❌ Impossible de détecter le logo — vérifiez le fichier source.")
        return

    left, top, right, bottom = bbox
    print(f"📦 BoundingBox détectée : left={left}, top={top}, right={right}, bottom={bottom}")
    print(f"   Espace blanc haut : {top}px | bas : {im.height - bottom}px")
    print(f"   Espace blanc gauche : {left}px | droite : {im.width - right}px")

    # --- Étape 4 : Recadrer sur le logo uniquement ---
    cropped = im.crop(bbox)
    crop_w, crop_h = cropped.size
    print(f"✂️  Logo recadré : {crop_w}x{crop_h}")

    # --- Étape 5 : Canvas 1024x1024 avec padding uniforme de 8% ---
    canvas_size = 1024
    padding = int(canvas_size * 0.18)  # 18% de marge de chaque côté (moins zoomé)
    max_logo_size = canvas_size - (padding * 2)

    # Redimensionner en gardant le ratio
    ratio = min(max_logo_size / crop_w, max_logo_size / crop_h)
    new_w = int(crop_w * ratio)
    new_h = int(crop_h * ratio)
    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    print(f"🔄 Logo redimensionné : {new_w}x{new_h}")

    # --- Étape 6 : Centrage parfait sur le canvas ---
    new_im = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    offset_x = (canvas_size - new_w) // 2
    offset_y = (canvas_size - new_h) // 2
    new_im.paste(resized, (offset_x, offset_y), resized)

    print(f"📍 Position dans le canvas : x={offset_x}, y={offset_y}")
    print(f"   Marge haut: {offset_y}px | bas: {canvas_size - offset_y - new_h}px")
    print(f"   Marge gauche: {offset_x}px | droite: {canvas_size - offset_x - new_w}px")

    # --- Étape 7 : Sauvegarde ---
    new_im.save(source_path)
    print(f"\n✅ Logo recentré et sauvegardé : {source_path}")
    print("👉 Lance maintenant : dart run flutter_launcher_icons")

if __name__ == "__main__":
    fix_icon_center()
