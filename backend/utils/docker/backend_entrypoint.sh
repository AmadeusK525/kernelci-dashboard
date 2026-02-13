#!/bin/sh
export PYTHONOPTIMIZE=${PYTHONOPTIMIZE:-2}
export PYTHONUNBUFFERED=${PYTHONUNBUFFERED:-1}

set -e

# Initialize Prometheus metrics before Django starts
PROMETHEUS_METRICS_ENABLED=$(echo "$PROMETHEUS_METRICS_ENABLED" | tr '[:upper:]' '[:lower:]')
if [ "$PROMETHEUS_METRICS_ENABLED" = "true" ]; then
    echo "Initializing Prometheus metrics before Django startup..."
    PROMETHEUS_METRICS_PORT=${PROMETHEUS_METRICS_PORT:-8001}
    PROMETHEUS_MULTIPROC_DIR=${PROMETHEUS_MULTIPROC_DIR:-/tmp/prometheus_multiproc_dir}
    export PROMETHEUS_MULTIPROC_DIR
    export PROMETHEUS_METRICS_PORT
    
    rm -f $PROMETHEUS_MULTIPROC_DIR/*.db || true
    
    python3 utils/prometheus_aggregator.py &
fi

# Add and start cronjobs
poetry run ./manage.py crontab add
crond start

# Update the sqlite cache db
chmod +x ./migrate-cache-db.sh
./migrate-cache-db.sh

# To update the app db, run MANNUALLY:
# docker compose run --rm backend sh -c "chmod +x ./migrate-app-db.sh && ./migrate-app-db.sh"

exec "$@"
