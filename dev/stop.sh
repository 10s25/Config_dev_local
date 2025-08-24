#!/bin/bash

echo "🛑 Arrêt du serveur de développement..."
echo "===================================="

PORT=8000

# Méthode 1: Trouver par port
PID=$(lsof -Pi :$PORT -sTCP:LISTEN -t 2>/dev/null)

if [ ! -z "$PID" ]; then
    echo "🔍 Serveur trouvé sur port $PORT (PID: $PID)"
    kill -9 $PID 2>/dev/null
    echo "✅ Processus $PID arrêté"
fi

# Méthode 2: Trouver tous les serveurs Python
PIDS=$(pgrep -f "python.*server.py" 2>/dev/null)
if [ ! -z "$PIDS" ]; then
    echo "� Prrocessus server.py trouvés: $PIDS"
    for pid in $PIDS; do
        kill -9 $pid 2>/dev/null
        echo "✅ Processus $pid arrêté"
    done
fi

# Attendre un peu
sleep 2

# Vérification finale
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Le port $PORT est encore utilisé"
else
    echo "✅ Port $PORT libéré"
fi