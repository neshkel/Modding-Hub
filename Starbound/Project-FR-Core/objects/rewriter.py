import os
import json
from pathlib import Path

# --- CONFIGURATION ---
# Le script s'exécute dans le dossier où il est placé
BASE_DIR = Path(__file__).parent.absolute()

# Le contenu exact à injecter
NEW_PATCH_CONTENT = [ { "op": "add", "path": "/builder", "value": "/items/buildscripts/buildobject.lua" } ]

def rewrite_all_patches():
    print(f"🚀 Réécriture récursive des fichiers .patch dans : {BASE_DIR}")
    print("-" * 50)
    
    count = 0
    
    # rglob('**/*.patch') cherche tous les .patch dans tous les sous-dossiers
    for patch_file in BASE_DIR.rglob('*.patch'):
        try:
            # On écrase le contenu du fichier
            with open(patch_file, 'w', encoding='utf-8') as f:
              json.dump(NEW_PATCH_CONTENT, f, separators=(',', ':'), ensure_ascii=False)
            
            # Affichage du chemin relatif pour le suivi
            print(f"✅ Mis à jour : {patch_file.relative_to(BASE_DIR)}")
            count += 1
            
        except Exception as e:
            print(f"❌ Erreur lors de l'écriture de {patch_file.name} : {e}")

    print("-" * 50)
    print(f"✨ Terminé ! {count} fichiers .patch ont été réécrits avec succès.")

if __name__ == "__main__":
    # Petite sécurité pour confirmer avant de tout écraser
    confirm = input(f"ATTENTION : Ce script va écraser TOUS les fichiers .patch dans {BASE_DIR} et ses sous-dossiers.\nContinuer ? (o/n) : ")
    if confirm.lower() == 'o':
        rewrite_all_patches()
    else:
        print("Opération annulée.")