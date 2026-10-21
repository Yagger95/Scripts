#!/bin/bash

# Define array of potential OS php.ini locations (Debian/Ubuntu vs RHEL/AlmaLinux/Rocky)
OS_INIS=(
    "/etc/php.ini"
    "/etc/php/*/cli/php.ini"
    "/etc/php/*/apache2/php.ini"
    "/etc/php/*/fpm/php.ini"
)

# 1. Update Plesk PHP versions
for ini in /opt/plesk/php/*/etc/php.ini; do
    if [ -f "$ini" ]; then
        if grep -q "session.upload_progress.enabled" "$ini"; then
            sed -i 's/^;\?\s*session.upload_progress.enabled\s*=.*/session.upload_progress.enabled = Off/' "$ini"
        else
            echo "session.upload_progress.enabled = Off" >> "$ini"
        fi
        echo "Updated Plesk PHP: $ini"
    fi
done

# 2. Update OS system PHP versions
for pattern in "${OS_INIS[@]}"; do
    for ini in $pattern; do
        if [ -f "$ini" ]; then
            if grep -q "session.upload_progress.enabled" "$ini"; then
                sed -i 's/^;\?\s*session.upload_progress.enabled\s*=.*/session.upload_progress.enabled = Off/' "$ini"
            else
                echo "session.upload_progress.enabled = Off" >> "$ini"
            fi
            echo "Updated OS PHP: $ini"
        fi
    done
done

# 3. Reiniciar todos los servicios PHP-FPM activos
echo "Reiniciando PHP-FPM..."

systemctl list-units --type=service --state=active --no-legend --plain \
  | awk '$1 ~ /^(plesk-php.*-fpm.*|php.*-fpm)\.service$/ {print $1}' \
  | while read -r service; do
      echo "Reiniciando $service"
      systemctl restart "$service" || echo "ERROR reiniciando $service"
    done

# Reiniciar Apache
if systemctl is-active --quiet apache2; then
    systemctl restart apache2
elif systemctl is-active --quiet httpd; then
    systemctl restart httpd
fi

echo "Mitigacion aplicada."
