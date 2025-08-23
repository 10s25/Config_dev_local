#!/bin/bash

echo "🚀 Démarrage du serveur de développement..."
echo "===================================="

# Se placer dans le bon dossier
cd "$(dirname "$0")/.."

# Vérifier qu'on est dans le bon dossier
if [ ! -f "server.py" ]; then
    echo "❌ Erreur: server.py non trouvé. Lancez d'abord ./dev/setup.sh"
    exit 1
fi

PORT=8000

# Arrêter tout serveur existant
echo "🧹 Nettoyage des anciens processus..."
pkill -f "python.*server.py" 2>/dev/null || true
sleep 1
./dev/stop.sh >/dev/null 2>&1
sleep 2

# Vérifier que le port est libre
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "❌ Le port $PORT est encore utilisé. Arrêt forcé..."
    PID=$(lsof -Pi :$PORT -sTCP:LISTEN -t 2>/dev/null)
    if [ ! -z "$PID" ]; then
        kill -9 $PID 2>/dev/null
        sleep 2
    fi
fi

echo "🔧 Démarrage du serveur Python sur le port $PORT..."

# Démarrer le serveur avec chemin absolu
/usr/bin/python3 ./server.py &
SERVER_PID=$!

# Attendre un peu que le serveur démarre
sleep 3

# Vérifier que le serveur a bien démarré
if kill -0 $SERVER_PID 2>/dev/null && lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "✅ Serveur démarré avec succès !"
    echo ""
    echo "🌐 Accès: http://localhost:$PORT"
    echo "📁 Dossier: $(pwd)"
    echo "🔄 PID: $SERVER_PID"
    echo ""
    echo "💡 Conseils:"
    echo "   - Ctrl+C pour arrêter le serveur"
    echo "   - ./dev/stop.sh pour arrêter depuis un autre terminal"
    echo ""
    
    # Ouvrir le navigateur automatiquement
    if command -v xdg-open >/dev/null 2>&1; then
        echo "🌐 Ouverture automatique du navigateur..."
        xdg-open "http://localhost:$PORT" >/dev/null 2>&1 &
    fi
    
    # Attendre que le serveur se termine
    wait $SERVER_PID
else
    echo "❌ Erreur: Le serveur n'a pas pu démarrer"
    if kill -0 $SERVER_PID 2>/dev/null; then
        kill $SERVER_PID 2>/dev/null
    fi
    exit 1
fi
