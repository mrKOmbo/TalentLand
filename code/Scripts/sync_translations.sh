#!/bin/bash

# Script para sincronizar claves de traducción
# Agrega claves faltantes de en.lproj a todos los demás idiomas

BASE_DIR="/Users/milo/Documents/Me Apps/atenea/atenea"
REFERENCE="en.lproj/Localizable.strings"

cd "$BASE_DIR"

echo "🔄 Sincronizando traducciones..."
echo "📋 Referencia: $REFERENCE"
echo ""

# Extraer todas las claves del archivo de referencia
grep -o '^"[^"]*"' "$REFERENCE" | sort > /tmp/en_keys.txt

# Para cada directorio de idioma
for lang_dir in *.lproj; do
    lang=$(basename "$lang_dir" .lproj)
    file="$lang_dir/Localizable.strings"

    # Skip English (reference)
    if [ "$lang" = "en" ]; then
        continue
    fi

    if [ ! -f "$file" ]; then
        echo "⚠️  Saltando $lang (archivo no encontrado)"
        continue
    fi

    # Extraer claves existentes
    grep -o '^"[^"]*"' "$file" | sort > "/tmp/${lang}_keys.txt"

    # Encontrar claves faltantes
    missing_keys=$(comm -23 /tmp/en_keys.txt "/tmp/${lang}_keys.txt")
    missing_count=$(echo "$missing_keys" | wc -l)

    if [ -n "$missing_keys" ] && [ "$missing_count" -gt 0 ]; then
        echo "📝 $lang: Agregando $missing_count claves faltantes..."

        # Backup del archivo original
        cp "$file" "${file}.backup"

        # Agregar claves faltantes al final del archivo
        echo "" >> "$file"
        echo "// MARK: - Missing Keys (Added automatically - needs translation)" >> "$file"

        while IFS= read -r key; do
            # Limpiar comillas
            clean_key=$(echo "$key" | tr -d '"')

            # Obtener el valor del archivo en inglés
            value=$(grep "^$key = " "$REFERENCE" | sed 's/^"[^"]*" = "\(.*\)";$/\1/')

            # Agregar la clave con el valor en inglés (placeholder)
            echo "$key = \"$value\";" >> "$file"
        done <<< "$missing_keys"

        echo "✅ $lang: Actualizado (backup guardado como ${file}.backup)"
    else
        echo "✅ $lang: Completo (todas las claves presentes)"
    fi
done

echo ""
echo "🎉 ¡Sincronización completa!"
echo ""
echo "⚠️  IMPORTANTE: Las claves nuevas usan texto en inglés como placeholder."
echo "   Necesitas traducir estas claves manualmente al idioma correspondiente."
