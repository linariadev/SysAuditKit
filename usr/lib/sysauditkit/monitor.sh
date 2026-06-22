#!/bin/bash

USERNAME=""
TOP_N=""
KILL_PID=""
RENICE_PID=""
NICE_VALUE=""
SEARCH_PATTERN=""

show_help() {
    cat << EOF
Module MONITOR - Surveillance et gestion des processus

Usage: sysauditkit monitor [OPTIONS]

Options:
  -u, --user USERNAME    Afficher les processus d'un utilisateur
  -t, --top N            Afficher les N processus gourmands (défaut: 10)
  -k, --kill PID         Tuer un processus
  -r, --renice PID NICE  Modifier la priorité
  -s, --search PATTERN   Rechercher un processus par nom
  -h, --help             Afficher cette aide

Exemples:
  sysauditkit monitor -u lina
  sysauditkit monitor -t 5
  sysauditkit monitor -s firefox

EOF
}

show_user_processes() {
    local username="$1"
    
    echo "=== Processus de l'utilisateur: $username ==="
    echo ""
    
    if ! id "$username" &>/dev/null; then
        echo "Erreur: L'utilisateur '$username' n'existe pas"
        return 1
    fi
    
    echo "PID    %CPU  %MEM  COMMAND"
    echo "----------------------------------------"
    ps -u "$username" -o pid,%cpu,%mem,comm --no-headers | head -n 20
    
    local proc_count=$(ps -u "$username" --no-headers | wc -l)
    echo ""
    echo "Total: $proc_count processus"
}

show_top_processes() {
    local count="${1:-10}"
    echo "=== Top $count Processus Gourmands ==="
    echo ""
    
    echo "--- Par CPU ---"
    ps aux --sort=-%cpu | head -n $((count + 1))
    
    echo ""
    echo "--- Par Mémoire ---"
    ps aux --sort=-%mem | head -n $((count + 1))
}

search_process() {
    local pattern="$1"
    
    echo "=== Recherche de processus: $pattern ==="
    echo ""
    
    local results=$(pgrep -a "$pattern")
    
    if [ -z "$results" ]; then
        echo "Aucun processus trouvé correspondant à '$pattern'"
        return 1
    fi
    
    echo "PID    COMMAND"
    echo "----------------------------------------"
    echo "$results"
    local proc_count=$(echo "$results" | wc -l)
    echo ""
    echo "$proc_count processus trouvé(s)"
}

kill_process() {
    local pid="$1"
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "Erreur: PID invalide '$pid'"
        return 1
    fi
    
    if ! ps -p "$pid" &>/dev/null; then
        echo "Erreur: Le processus $pid n'existe pas"
        return 1
    fi

    echo "Information sur le processus:"
    ps -p "$pid" -o pid,user,%cpu,%mem,comm
    echo ""
    
    read -p "Voulez-vous vraiment tuer ce processus? (o/N): " reponse
    if [[ "$reponse" =~ ^[oO]$ ]]; then
        if kill "$pid" 2>/dev/null; then
            echo "Processus $pid terminé"
        else
            echo "Erreur: Impossible de tuer le processus $pid"
            echo "Essayez avec sudo ou kill -9"
            return 1
        fi
    else
        echo "Opération annulée"
    fi
}

renice_process() {
    local pid="$1"
    local nice_value="$2"
    
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "Erreur: PID invalide '$pid'"
        return 1
    fi
    
    if ! [[ "$nice_value" =~ ^-?[0-9]+$ ]]; then
        echo "Erreur: Valeur nice invalide '$nice_value'"
        echo "La valeur doit être entre -20 (haute priorité) et 19 (basse priorité)"
        return 1
    fi
    
    if ! ps -p "$pid" &>/dev/null; then
        echo "Erreur: Le processus $pid n'existe pas"
        return 1
    fi
    
    echo "Processus avant modification:"
    ps -p "$pid" -o pid,user,nice,comm
    echo ""

    if renice "$nice_value" -p "$pid" &>/dev/null; then
        echo "Priorité modifiée"
        echo ""
        echo "Processus après modification:"
        ps -p "$pid" -o pid,user,nice,comm
    else
        echo "Erreur: Impossible de modifier la priorité"
        echo "Vous avez besoin des privilèges root pour diminuer la valeur nice"
        return 1
    fi
}

ARGS=$#
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user)
            USERNAME="$2"
            shift 2
            ;;
        -t|--top)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
            TOP_N="$2"
            shift 2
            else
            TOP_N="10"
            shift 1
            fi
            ;;
        -k|--kill)
            KILL_PID="$2"
            shift 2
            ;;
        -r|--renice)
            RENICE_PID="$2"
            NICE_VALUE="$3"
            shift 3
            ;;
        -s|--search)
            SEARCH_PATTERN="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

if [ $ARGS -eq 0 ]; then
    show_help
    exit 0
fi

echo "=== Mode MONITOR ==="

if [ -n "$USERNAME" ]; then
    echo ""
    show_user_processes "$USERNAME"
fi

if [ -n "$TOP_N" ]; then
    echo ""
    show_top_processes "$TOP_N"
fi

if [ -n "$SEARCH_PATTERN" ]; then
    echo ""
    search_process "$SEARCH_PATTERN"
fi

if [ -n "$KILL_PID" ]; then
    echo ""
    kill_process "$KILL_PID"
fi

if [ -n "$RENICE_PID" ] && [ -n "$NICE_VALUE" ]; then
    echo ""
    renice_process "$RENICE_PID" "$NICE_VALUE"
fi
