#!/bin/bash
# Hit the live service every 0.1s and record status + version (zero-downtime check)
end=$((SECONDS + ${1:-40}))
while [ $SECONDS -lt $end ]; do
  out=$(curl -s -m 2 -w ' HTTP=%{http_code}' http://localhost:8000)
  ver=$(echo "$out" | grep -o 'Version: v[0-9]' | cut -d' ' -f2)
  echo "$(date +%T.%3N) ${out##* } ${ver:-none}"
  sleep 0.1
done
