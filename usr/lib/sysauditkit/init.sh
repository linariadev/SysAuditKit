#!/bin/bash

CONF="/etc/sysauditkit/owner.conf"
LOG="/var/log/sysauditkit/init.log"
mkdir -p /var/log/sysauditkit
mkdir -p /etc/sysauditkit

log_action() {
if [ ! -f "$LOG" ]; then
touch "$LOG"
fi

local message="$1"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG"
}

prenom=""
nom=""
while [[ -z "$prenom" ]]; do
    read -p "Entrez votre prénom : " prenom
done
while [[ -z "$nom" ]]; do
    read -p "Entrez votre nom : " nom
done

identifiant=$(echo "$prenom $nom" | tr '[:upper:]' '[:lower:]' | tr -d ' ')


if id "$identifiant" &>/dev/null; then
    echo "L'utilisateur $identifiant existe déjà!"
    log_action "Utilisateur existant: $identifiant"
    exit 1
else
    echo "Création de l'utilisateur $identifiant..."
    if useradd -m "$identifiant" -s /bin/bash -c "$prenom $nom"; then
        echo "Utilisateur créé avec succès : $identifiant"
        log_action "Création identifiant pour $prenom $nom : $identifiant"
    else
        echo "Erreur lors de la création de l'utilisateur"
        log_action "ERREUR: Échec création utilisateur $identifiant"
        exit 1
    fi
fi

WORK_DIR="/home/$identifiant/workspace"
echo ""
echo "Création du workspace: $WORK_DIR"

if mkdir -p "$WORK_DIR"; then
    log_action "Dossier créé: $WORK_DIR"
    
    chown "$identifiant:$identifiant" "$WORK_DIR"
    chmod 755 "$WORK_DIR"
    
    echo "Workspace prêt!"
    log_action "Permissions configurées pour: $WORK_DIR"
else
    echo "Erreur lors de la création du workspace"
    log_action "ERREUR: échec création du workspace $WORK_DIR"
    exit 1
fi

echo "Sauvegarde de la configuration dans $CONF..."

cat > "$CONF" << EOF
# Configuration SysAuditKit
# Généré le $(date '+%Y-%m-%d %H:%M:%S')

PRENOM="$prenom"
NOM="$nom"
IDENTIFIANT="$identifiant"
WORK_DIR="$WORK_DIR"
DATE_CREATION="$(date '+%Y-%m-%d')"
EOF

chmod 644 "$CONF"
echo "Configuration sauvegardée"
log_action "Configuration sauvegardée: $CONF"

