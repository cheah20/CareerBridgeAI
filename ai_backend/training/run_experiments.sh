#!/bin/bash
# Run the synthetic-data experiments one after the other, gently (pause after each step),
# with the heat guard on and every log kept for the report.
#   bash training/run_experiments.sh            (from ai_backend/)
# Each experiment's logs end up in data/training_runs/<name>/:
#   progress.log  train.log  gpu.csv (one sample per minute)  metrics.json  command.txt
cd "$(dirname "$0")/.." || exit 1
PY=~/miniconda3/envs/careerbridge-train/bin/python
THROTTLE=${THROTTLE:-1.0}     # seconds of rest after each step
HEAT_LIMIT=${HEAT_LIMIT:-85}  # °C; lower than usual because nobody is watching

run() {  # name, output folder, extra-data file, repeat
  local name=$1 out=$2 extra=$3 repeat=$4 dir=data/training_runs/$1
  mkdir -p "$dir"
  local cmd="$PY -W ignore training/finetune_transformer.py --extra $extra --extra-repeat $repeat --out $out --throttle $THROTTLE"
  echo "$cmd" > "$dir/command.txt"
  echo "$(date '+%F %T') $name started (throttle ${THROTTLE}s, heat limit ${HEAT_LIMIT}C)"
  nvidia-smi --query-gpu=timestamp,temperature.gpu,power.draw,utilization.gpu,memory.used --format=csv -l 60 > "$dir/gpu.csv" &
  local gpu_logger=$!
  $cmd > data/training_runs/train.log 2>&1 &
  local trainer=$!
  sleep 10
  bash training/heat_guard.sh "$HEAT_LIMIT" >> "$dir/heat_guard.log" 2>&1 &
  wait $trainer
  local status=$?
  kill $gpu_logger 2>/dev/null
  cp data/training_runs/progress.log data/training_runs/train.log "$dir/"
  [ -f "$out/metrics.json" ] && cp "$out/metrics.json" "$dir/"
  echo "$(date '+%F %T') $name finished (exit $status)"
  return $status
}

run exp1-rough   models/candidate-synth1 data/eval/my_synthetic_v1.jsonl      10 || exit 1
run exp2-refined models/candidate-synth2 data/synthetic/batch1/train_45.jsonl 4
