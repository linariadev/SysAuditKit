#!/bin/bash

CONF="/etc/sysauditkit/owner.conf"
LOG="/var/log/sysauditkit/report.log"

mkdir -p /var/log/sysauditkit

log_action() {
    local message="$1"
    if [ -w "$(dirname "$LOG")" ] || [ -w "$LOG" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG"
    else
        echo "Erreur: Impossible d'écrire dans $LOG" >&2
    fi
}

if [ -f "$CONF" ]; then
    source "$CONF"
else
    echo "Configuration non trouvée. Exécutez d'abord: sudo sysauditkit init"
    exit 1
fi

REPORT_DATE=$(date '+%Y%m%d_%H%M%S')
REPORT_FILE="/tmp/report_${IDENTIFIANT}_${REPORT_DATE}.txt"

log_action "Début génération du report: $REPORT_FILE"

{
    echo "# SYSTEM AUDIT REPORT - SYSAUDITKIT"
    echo "Rapport généré le: $(date '+%d/%m/%Y à %H:%M:%S')"
    echo "Généré par: $PRENOM $NOM" 
    echo "Identifiant: $IDENTIFIANT"
    echo ""
    echo "--- INFORMATIONS SYSTÈME ---"
    echo "OS            : $(grep 'PRETTY_NAME' /etc/os-release | cut -d'"' -f2)"
    echo "Kernel        : $(uname -r)"
    echo "Architecture  : $(uname -m)"
    echo "Hostname      : $(hostname)"
    echo "Uptime        : $(uptime -p)"
    echo ""
    echo "--- USAGE DISQUE ---"
    df -h 
    echo ""
    echo "--- UTILISATEURS CONNECTÉS ---"
    who
    echo "Nombre d'utilisateurs connectés: $(who | wc -l)"
    echo ""
    echo "--- PROCESSUS ACTIFS (TOP 10) ---"
    echo "[CPU]"
    ps aux --sort=-%cpu | head -n 11 
    echo ""
    echo "[MEMOIRE]"
    ps aux --sort=-%mem | head -n 11
    echo ""
    echo "--- UTILISATION MÉMOIRE ---"
    free -h
    echo ""
} > "$REPORT_FILE"

if [ -f "$REPORT_FILE" ]; then
    echo "Rapport généré avec succès!"
    echo "Fichier: $REPORT_FILE"
    echo ""
    echo "Pour voir le rapport: cat $REPORT_FILE"
    log_action "Report généré: $REPORT_FILE"
else 
    echo "Erreur lors de la création du rapport."
    log_action "ERREUR: échec création à $REPORT_FILE"
    exit 1
fi
