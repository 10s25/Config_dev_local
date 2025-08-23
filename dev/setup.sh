#!/bin/bash  #

# Script de configuration automatique du projet
# Usage: ./dev/setup.sh

set -e

echo "🚀 Configuration automatique du projet site"
echo "================================================"

# Vérifier qu'on est dans le bon dossier
if [ ! -f "index.html" ]; then
    echo "❌ Erreur: Lancez ce script depuis la racine du projet (où se trouve index.html)"
    exit 1
fi

echo "📁 Création des dossiers nécessaires..."
mkdir -p local/ssi
mkdir -p global/ssi
mkdir -p dev

echo "📝 Création du fichier .htaccess principal..."

# Sauvegarder l'ancien .htaccess si il existe
if [ -f ".htaccess" ]; then
    cp .htaccess .htaccess.prod.bak 2>/dev/null || echo "   ⚠️  Impossible de sauvegarder .htaccess (permissions)"
fi

# Créer le nouveau .htaccess (avec gestion des permissions)
{
cat > .htaccess << 'EOF'
Options +Includes +FollowSymLinks
AddType text/html .shtml .html
AddOutputFilter INCLUDES .shtml .html
AddHandler server-parsed .html
DirectoryIndex index.html
XBitHack on
EOF
} 2>/dev/null || {
    echo "   ⚠️  Impossible d'écrire .htaccess (permissions). Création de .htaccess.dev à la place"
    cat > .htaccess.dev << 'EOF'
Options +Includes +FollowSymLinks
AddType text/html .shtml .html
AddOutputFilter INCLUDES .shtml .html
AddHandler server-parsed .html
DirectoryIndex index.html
XBitHack on
EOF
    echo "   💡 Copiez manuellement .htaccess.dev vers .htaccess avec sudo si nécessaire"
}

echo "📝 Création du fichier .htaccess pour SSI legacy..."
cat > local/ssi/.htaccess << 'EOF'
SSILegacyExprParser on
EOF

echo "📝 Création du menu de développement (sans conditions SSI)..."

# Supprimer les anciennes sauvegardes problématiques
rm -f local/ssi/menu_top.shtml.dev.bak
rm -f local/ssi/menu_top.shtml.prod.bak

# Toujours créer un menu de dev propre (sans commentaires ni conditions SSI)
cat > local/ssi/menu_top.shtml << 'EOF'
<li><a href="/local/visuels.html">Visuels</a></li>
<li class="dropdown">
	<a href="#" class="disabled">Doleances</a>
	<ul class="submenu">
		<li><a href="/local/formulaire-doleances.html">Formulaire</a></li>
		<li><a href="/local/doleances.html">Cahier</a></li>
	</ul>
</li>
EOF
echo "   ✅ Menu de développement créé (sans conditions SSI)"

echo "📝 Création des fichiers SSI manquants..."
if [ ! -f "local/ssi/emails.shtml" ]; then
    echo '<a href="mailto:contact@example.com">contact@example.com</a>' > local/ssi/emails.shtml
fi

if [ ! -f "local/ssi/gpg.shtml" ]; then
    echo 'Clé GPG à configurer' > local/ssi/gpg.shtml
fi

echo "🐍 Création du serveur Python avec SSI..."
cat > server.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import re

class SSIHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path.endswith('.html') or self.path == '/':
            try:
                if self.path == '/':
                    filepath = 'index.html'
                else:
                    filepath = self.path.lstrip('/')
                
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                content = self.process_ssi(content)
                
                self.send_response(200)
                self.send_header('Content-type', 'text/html; charset=utf-8')
                self.end_headers()
                self.wfile.write(content.encode('utf-8'))
            except FileNotFoundError:
                super().do_GET()
        else:
            super().do_GET()
    
    def process_ssi(self, content):
        # Traiter les includes d'abord
        pattern = r'<!--#include virtual="([^"]+)" -->'
        
        def replace_include(match):
            include_path = match.group(1)
            try:
                with open(include_path, 'r', encoding='utf-8') as f:
                    included_content = f.read()
                    # Traiter récursivement les SSI dans le fichier inclus
                    return self.process_ssi_simple(included_content)
            except FileNotFoundError:
                return f'<!-- File not found: {include_path} -->'
        
        content = re.sub(pattern, replace_include, content)
        
        # Nettoyer les autres directives SSI
        return self.process_ssi_simple(content)
    
    def process_ssi_simple(self, content):
        # Supprimer complètement les directives SSI non supportées
        content = re.sub(r'<!--#config[^>]*-->', '', content)
        content = re.sub(r'<!--#echo[^>]*-->', '', content)
        
        # Pour les conditions if/endif, supprimer les balises mais garder le contenu
        # Traiter les conditions imbriquées
        while re.search(r'<!--#if[^>]*-->.*?<!--#endif[^>]*-->', content, re.DOTALL):
            content = re.sub(r'<!--#if[^>]*-->(.*?)<!--#endif[^>]*-->', r'\1', content, flags=re.DOTALL)
        
        # Nettoyer les if/endif orphelins
        content = re.sub(r'<!--#if[^>]*-->', '', content)
        content = re.sub(r'<!--#endif[^>]*-->', '', content)
        
        return content

PORT = 8000

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

with ReusableTCPServer(("localhost", PORT), SSIHandler) as httpd:
    print(f"Server running at http://localhost:{PORT}")
    httpd.serve_forever()
EOF

chmod +x server.py

echo "🔧 Génération du fichier groupes.shtml..."
if [ -f "src/update_groups.php" ] && command -v php >/dev/null 2>&1; then
    cd src
    php update_groups.php >/dev/null 2>&1 || echo "⚠️  Erreur lors de la génération des groupes (normal si pas de PHP)"
    cd ..
else
    echo "⚠️  PHP non trouvé, création d'un fichier groupes.shtml basique..."
    cat > global/ssi/groupes.shtml << 'EOF'
<ul class="sidebar-section-1">
    <li>
        <h3 class="font-yellow">Réseaux sociaux</h3>
        <ul class="sidebar-section-2">
            <li>
                <ul>
                    <li class="telegram">
                        <p>Telegram</p>
                        <ul>
                            <li><a href="https://t.me/+B5CJp-RUGpAzMmQ8" target="_blank" rel="me">+B5CJp-RUGpAzMmQ8</a></li>
                        </ul>
                    </li>
                </ul>
            </li>
        </ul>
    </li>
</ul>
EOF
fi

echo "📝 Création du script de démarrage..."
cat > dev/start.sh << 'EOF'
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
EOF

chmod +x dev/start.sh

echo "🔧 Attribution des permissions d'exécution aux scripts..."
chmod +x dev/stop.sh
chmod +x dev/prod.sh
chmod +x dev/setup.sh

echo ""
echo "✅ Configuration terminée !"
echo ""
echo "🎯 Pour démarrer le serveur :"
echo "   ./dev/start.sh"
echo "   ou"
echo "   python3 server.py"
echo ""
echo "🌐 Puis ouvrir : http://localhost:8000"
echo ""
echo "📋 Fichiers créés/modifiés :"
echo "   - .htaccess (SSI activés)"
echo "   - local/ssi/.htaccess (SSI legacy)"
echo "   - local/ssi/menu_top.shtml (corrigé)"
echo "   - server.py (serveur Python avec SSI)"
echo "   - dev/start.sh (script de démarrage)"
echo ""
