#!/bin/bash
# Stop GPU training automatically if the GPU reaches LIMIT °C. Checks every 5 seconds;
# exits by itself when training ends.
#   bash training/heat_guard.sh [LIMIT]      (default 89)
LIMIT=${1:-89}
LOG="$(dirname "$0")/../data/training_runs/progress.log"
PATTERN="[c]areerbridge-train/bin/python.*finetune_transformer"  # [c] keeps this script from matching itself

echo "heat guard on: stop training at ${LIMIT}C"
while pid=$(pgrep -f "$PATTERN" | head -1); [ -n "$pid" ]; do
  temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
  if [ -n "$temp" ] && [ "$temp" -ge "$LIMIT" ]; then
    kill -TERM "$pid"
    msg="$(date +%H:%M:%S) STOPPED BY HEAT GUARD: GPU reached ${temp}C (limit ${LIMIT}C)"
    echo "$msg" | tee -a "$LOG"
    exit 2
  fi
  sleep 5
done
echo "training finished; heat guard off (GPU never reached ${LIMIT}C)"
