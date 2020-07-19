#!/usr/bin/env bash
# When using cron path of the secret must be absolutely
[ ! -f ./secrets ] && \
  echo 'secrets file is missing!' && \
  exit 1

source ./secrets

# Exit if the RECORD_IDS array has no elements
[ ${#RECORD_IDS[@]} -eq 0 ] && \
  echo 'RECORD_IDS are missing!' && \
  exit 1

public_ip=$(curl -s http://checkip.amazonaws.com/)

for ID in "${RECORD_IDS[@]}"; do
  local_ip=$(
    curl \
      --fail \
      --silent \
      -X GET \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      "https://api.digitalocean.com/v2/domains/${DOMAIN}/records/${ID}" | \
      grep -Eo '"data":".*?"' | \
      grep -Eo '\d+\.\d+\.\d+\.\d+'
  )

  # if the IPs are the same just exit
  [ "$local_ip" == "$public_ip" ] && exit 0
  
  # if the IPs are same as array of whitelisted ones just exit
  [ ${#WHITE_IDS[@]} -eq $local_ip ] && exit 0

  # --fail silently on server errors
  curl \
    --fail \
    --silent \
    --output /dev/null \
    -X PUT \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -d "{\"data\": \"${public_ip}\"}" \
    "https://api.digitalocean.com/v2/domains/${DOMAIN}/records/${ID}"

done
