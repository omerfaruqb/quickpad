#!/bin/bash
# Script to run Locust load tests
# Usage: ./run-locust.sh [host] [users] [spawn-rate]

HOST=${1:-"http://localhost:5030"}
USERS=${2:-100}
SPAWN_RATE=${3:-10}
DURATION=${4:-"5m"}

echo "🚀 Starting Locust load test"
echo "Target: $HOST"
echo "Users: $USERS"
echo "Spawn rate: $SPAWN_RATE users/second"
echo "Duration: $DURATION"
echo ""

locust -f locustfile.py \
  --host="$HOST" \
  --users="$USERS" \
  --spawn-rate="$SPAWN_RATE" \
  --run-time="$DURATION" \
  --headless \
  --html=report.html \
  --csv=results

echo ""
echo "✅ Test completed! Check report.html for results"

