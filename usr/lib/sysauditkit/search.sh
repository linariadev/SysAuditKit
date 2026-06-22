#!/bin/bash

SEARCH_DIR=""
KEYWORDS=""
FILE_EXT=""
FILE_SIZE=""
OUTPUT_FILE="/tmp/search_results.txt"

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            SEARCH_DIR="$2"
            shift 2
            ;;
        -k|--keyword)
            KEYWORDS="$2"
            shift 2
            ;;
        -e|--ext)
            FILE_EXT="$2"
            shift 2
            ;;
        -s|--size)
            FILE_SIZE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: sysauditkit search [OPTIONS]"
            echo "  -d, --dir PATH       Répertoire de recherche"
            echo "  -k, --keyword WORD   Mot-clé à rechercher"
            echo "  -e, --ext EXT        Extension (.log, .txt)"
            echo "  -s, --size SIZE      Taille (+10M, -1k)"
            echo "  -o, --output FILE    Fichier de sortie"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done


if [ -z "$SEARCH_DIR" ]; then
    echo "Erreur: -d <répertoire> est obligatoire"
    exit 1
fi

if [ ! -d "$SEARCH_DIR" ]; then
    echo "Erreur: Le répertoire '$SEARCH_DIR' n'existe pas"
    exit 1
fi

echo "=== Paramètres de recherche ==="
echo "Répertoire: $SEARCH_DIR"
echo "Mot-clé: ${KEYWORDS:-aucun}"
echo "Extension: ${FILE_EXT:-toutes}"
echo "Taille: ${FILE_SIZE:-toutes}"
echo "Sortie: $OUTPUT_FILE"


echo ""
echo "=== TÂCHE 1 : RECHERCHE DE FICHIERS ==="

FIND_CMD="find \"$SEARCH_DIR\" -type f"

if [ -n "$FILE_EXT" ]; then
    FIND_CMD="$FIND_CMD -name \"*$FILE_EXT\""
fi

if [ -n "$FILE_SIZE" ]; then
    FIND_CMD="$FIND_CMD -size $FILE_SIZE"
fi

echo "Commande find: $FIND_CMD"
echo ""

cat > "$OUTPUT_FILE" << EOF
################################################################################
# RÉSULTATS DE RECHERCHE - SYSAUDITKIT
################################################################################
#
# Date: $(date '+%d/%m/%Y %H:%M:%S')
# Répertoire: $SEARCH_DIR
# Critères:
#   - Extension: ${FILE_EXT:-toutes}
#   - Taille: ${FILE_SIZE:-toutes}
#   - Mot-clé: ${KEYWORDS:-aucun}
#
################################################################################

=== TÂCHE 1 : FICHIERS TROUVÉS ===

EOF

TEMP_FIND=$(mktemp)
eval "$FIND_CMD" 2>/dev/null > "$TEMP_FIND"

FILE_COUNT=$(wc -l < "$TEMP_FIND")

if [ "$FILE_COUNT" -eq 0 ]; then
    echo "Aucun fichier trouvé"
    echo "Aucun fichier trouvé" >> "$OUTPUT_FILE"
else
    echo "$FILE_COUNT fichier(s) trouvé(s)"
    cat "$TEMP_FIND" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"

if [ -n "$KEYWORDS" ]; then
    echo ""
    echo "=== TÂCHE 2 : ANALYSE DU CONTENU ==="
    
    cat >> "$OUTPUT_FILE" << EOF

=== TÂCHE 2 : OCCURRENCES DU MOT-CLÉ "$KEYWORDS" ===

EOF
    
    TEMP_GREP=$(mktemp)
    grep -rni "$KEYWORDS" "$SEARCH_DIR" 2>/dev/null > "$TEMP_GREP"
    
    GREP_COUNT=$(wc -l < "$TEMP_GREP")
    
    if [ "$GREP_COUNT" -eq 0 ]; then
        echo "Aucune occurrence trouvée pour '$KEYWORDS'"
        echo "Aucune occurrence trouvée" >> "$OUTPUT_FILE"
    else
        echo "$GREP_COUNT occurrence(s) trouvée(s)"
        
        echo "Aperçu (10 premières lignes):"
        head -n 10 "$TEMP_GREP"
        if [ "$GREP_COUNT" -gt 10 ]; then
            echo "... ($(($GREP_COUNT - 10)) lignes supplémentaires)"
        fi
        cat "$TEMP_GREP" >> "$OUTPUT_FILE"
    fi
    
    rm -f "$TEMP_GREP"
    echo "" >> "$OUTPUT_FILE"
fi

if [ -n "$KEYWORDS" ] && [ "$FILE_COUNT" -gt 0 ]; then
    echo ""
    echo "=== TÂCHE 3 : RECHERCHE COMBINÉE (FIND + GREP) ==="
    
    cat >> "$OUTPUT_FILE" << EOF

=== TÂCHE 3 : COMBINAISON FIND + GREP ===
Recherche du mot-clé "$KEYWORDS" dans les fichiers trouvés par find

EOF
    
    TEMP_COMBINED=$(mktemp)

    while IFS= read -r filepath; do
        if [ -f "$filepath" ] && [ -r "$filepath" ]; then
            if file "$filepath" 2>/dev/null | grep -q text; then
                grep -Hn "$KEYWORDS" "$filepath" 2>/dev/null >> "$TEMP_COMBINED"
            fi
        fi
    done < "$TEMP_FIND"
    
    COMBINED_COUNT=$(wc -l < "$TEMP_COMBINED")
    
    if [ "$COMBINED_COUNT" -eq 0 ]; then
        echo "Aucune occurrence dans les fichiers sélectionnés"
        echo "Aucune occurrence trouvée" >> "$OUTPUT_FILE"
    else
        echo "$COMBINED_COUNT occurrence(s) dans les fichiers sélectionnés"

        echo "Aperçu (10 premières lignes):"
        head -n 10 "$TEMP_COMBINED"
        if [ "$COMBINED_COUNT" -gt 10 ]; then
            echo "... ($(($COMBINED_COUNT - 10)) lignes supplémentaires)"
        fi
        
        cat "$TEMP_COMBINED" >> "$OUTPUT_FILE"
    fi
    
    rm -f "$TEMP_COMBINED"
    echo "" >> "$OUTPUT_FILE"
fi

rm -f "$TEMP_FIND"

cat >> "$OUTPUT_FILE" << EOF

################################################################################
# FIN DES RÉSULTATS
################################################################################
EOF

echo ""
echo "Recherche terminée!"
echo "Résultats sauvegardés dans: $OUTPUT_FILE"
