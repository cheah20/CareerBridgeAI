#!/bin/bash
# Live training dashboard: GPU, memory, and the latest progress lines.
cd "$(dirname "$0")/.." || exit 1
LOG=data/training_runs/progress.log

while true; do
  gpu=$(nvidia-smi --query-gpu=temperature.gpu,power.draw,utilization.gpu,memory.used,memory.total \
        --format=csv,noheader,nounits 2>/dev/null)
  IFS=', ' read -r temp power util mem memt <<<"$gpu"
  if   [ -z "$temp" ];       then level="?  no GPU reading"
  elif [ "$temp" -ge 87 ];   then level="RED  too hot - consider stopping"
  elif [ "$temp" -ge 80 ];   then level="YELLOW  warm"
  else                            level="GREEN  safe"; fi
  ram=$(free -m | awk '/Mem:/{printf "%.1f / %.1f GB", $3/1024, $2/1024}')
  running=$(pgrep -f "training/finetune_transformer.py" >/dev/null && echo "running" || echo "not running")

  clear
  echo "CareerBridge AI - Transformer training ($running)        $(date +%H:%M:%S)"
  echo "-----------------------------------------------------------------------"
  printf "GPU   %s C   %s W   use %s%%   VRAM %s / %s MiB\n" "$temp" "$power" "$util" "$mem" "$memt"
  printf "RAM   %s      CPU load %s / %s\n" "$ram" "$(awk '{print $1}' /proc/loadavg)" "$(nproc)"
  echo "Safety: $level"
  echo "-----------------------------------------------------------------------"
  if [ -s "$LOG" ]; then
    grep -E "==|test|ONNX|chosen|DONE|export|checking" "$LOG" | tail -8
    echo "..."
    grep -E "^.{9}epoch" "$LOG" | tail -1
  else
    echo "(waiting for the first progress line - tokenising takes about a minute)"
  fi
  sleep 2
done
