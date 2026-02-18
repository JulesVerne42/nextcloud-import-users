#!/bin/bash

# === CONFIGURATION À ADAPTER ===
CONTAINER_NAME="NOM_DU_CONTENEUR"  # Remplacez par le nom de votre conteneur (ex: nextcloud-aio-nextcloud)
CSV_FILE="utilisateurs.csv"
USER_INSIDE_CONTAINER="www-data"
# ================================

# Ignorer la première ligne (en-tête) si vous la gardez
# tail -n +2 "$CSV_FILE" | while IFS=',' read -r username password displayname email group quota supervisor; do

# Lire directement le fichier (pas d'en-tête dans mon fichier)
while IFS=',' read -r username password displayname email group quota supervisor; do
    echo "Création de l'utilisateur : $username ($displayname)"
    echo "  Groupe : $group"
    echo "  Email : $email"
    echo "  Quota : $quota"

    # Créer le groupe s'il n'existe pas
    docker exec -u "$USER_INSIDE_CONTAINER" "$CONTAINER_NAME" \
        php occ group:add "$group" 2>/dev/null && echo "  Groupe $group créé"

    # Créer l'utilisateur
    docker exec -e OC_PASS="$password" -u "$USER_INSIDE_CONTAINER" "$CONTAINER_NAME" \
        php occ user:add "$username" \
        --display-name "$displayname" \
        --email "$email" \
        --password-from-env \
        --group "$group"

    # Définir le quota (commande supplémentaire)
    docker exec -u "$USER_INSIDE_CONTAINER" "$CONTAINER_NAME" \
        php occ user:setting "$username" files quota "$quota"

    echo "✅ Utilisateur $username créé avec succès"
    echo "---"
    
    # Petite pause pour ne pas surcharger le système
    sleep 1
    
done < "$CSV_FILE"

echo "🎉 Import terminé ! Tous les utilisateurs ont été créés."
