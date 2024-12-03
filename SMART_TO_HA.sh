#!/bin/bash
HA_URL="https://<HA_IP>:443"  
HA_TOKEN="<HA_TOKEN"
ENTITY_ID="sensor.smart_disks_<ServerName>"

get_smart_status() {
    smartctl -H /dev/$1 | grep -i "SMART overall-health" | awk '{print $NF}'
}

DISKS=$(lsblk -d -n -o NAME | grep -E "sd|nvme")

ATTRIBUTES=$(mktemp)
echo "{" > $ATTRIBUTES
for disk in $DISKS; do
    STATUS=$(get_smart_status $disk)
    echo "\"$disk\": \"$STATUS\"," >> $ATTRIBUTES
done
sed -i '$ s/,$//' $ATTRIBUTES
echo "}" >> $ATTRIBUTES

PAYLOAD=$(jq -n --arg state "OK" --slurpfile attributes $ATTRIBUTES \
    '{state: $state, attributes: $attributes[0]}')

### Debug...
#echo "Payload:"
#echo "$PAYLOAD"

curl -k -s -X POST -H "Authorization: Bearer $HA_TOKEN" \
     -H "Content-Type: application/json" \
     -d "$PAYLOAD" \
     "$HA_URL/api/states/$ENTITY_ID"

rm $ATTRIBUTES
