**Projet GitHub** : https://github.com/10s25/Config_dev_local

## Documentation

📖 **Site de documentation** : https://10s25.github.io/Config_dev_local/


### Option 1 : Apache local (Linux)

**Installation et configuration :**
```bash
# Installation Apache
sudo apt update
sudo apt install apache2

# Démarrage du service
sudo systemctl start apache2
sudo systemctl enable apache2
```

**Configuration SSI :**
Voir la documentation complète : [Configuration SSI](https://github.com/10s25/site/wiki/Configuration-SSI)

➜ http://localhost

### Option 2 : WAMP/MAMP (Windows/macOS)

**Windows - WAMP :**
- Téléchargez [WampServer](https://www.wampserver.com/)
- Installez et démarrez tous les services
- Placez le projet dans le dossier `www`

**macOS - MAMP :**
- Téléchargez [MAMP](https://www.mamp.info/)
- Installez et démarrez Apache
- Placez le projet dans le dossier `htdocs`

**Configuration SSI :**
Voir la documentation complète : [Configuration SSI](https://github.com/10s25/site/wiki/Configuration-SSI)

➜ http://localhost (WAMP/MAMP)

### Option 3 : Serveur Python (ligne de commande)

**Linux/macOS :**
```bash
# Permissions d'exécution (première fois seulement)
chmod +x dev/setup.sh

# Configuration initiale (attribue automatiquement les permissions aux autres scripts)
./dev/setup.sh

# Démarrage (détection automatique si déjà en cours)
./dev/start.sh

# Arrêt (depuis un autre terminal - RECOMMANDÉ)
# Ouvrir un nouveau terminal et aller dans le dossier du projet :
cd ~/Bureau/site-main
./dev/stop.sh
```

**Windows :**

Pour utiliser les scripts sur Windows, vous devez installer bash :

1. **Git Bash** (recommandé) :
   - Téléchargez et installez [Git for Windows](https://git-scm.com/download/win)
   - Git Bash sera disponible dans le menu Démarrer
   - Ouvrez Git Bash et naviguez vers votre projet

2. **WSL (Windows Subsystem for Linux)** :
   ```powershell
   # Dans PowerShell en tant qu'administrateur
   wsl --install
   # Redémarrez votre ordinateur
   # Puis ouvrez Ubuntu depuis le menu Démarrer
   ```

3. **MSYS2** :
   - Téléchargez [MSYS2](https://www.msys2.org/)
   - Suivez les instructions d'installation
   - Utilisez le terminal MSYS2

Une fois bash installé, utilisez les mêmes commandes :
```bash
# Permissions d'exécution (première fois seulement)
chmod +x dev/setup.sh

# Configuration initiale (attribue automatiquement les permissions aux autres scripts)
./dev/setup.sh

# Démarrage (détection automatique si déjà en cours)
./dev/start.sh

# Arrêt (depuis un autre terminal - RECOMMANDÉ)
# Ouvrir un nouveau terminal et aller dans le dossier du projet :
cd ~/Bureau/site-main
./dev/stop.sh
```

➜ http://localhost:8000

**Fonctionnalités du serveur de développement :**
- ✅ **Configuration automatique** : Le script setup.sh génère automatiquement le serveur Python
- ✅ **Démarrage intelligent** : Détecte et arrête les anciens processus automatiquement
- ✅ **Gestion des ports** : Libération automatique du port 8000 avec plusieurs tentatives
- ✅ **Ouverture automatique** : Lance le navigateur automatiquement
- ✅ **Arrêt propre** : Script dédié pour arrêter le serveur avec nettoyage complet
- ✅ **Support SSI** : Simulation complète des Server-Side Includes pour le développement
- ✅ **Menu de développement** : Génération automatique d'un menu sans conditions SSI
- ✅ **Réutilisation d'adresse** : Serveur configuré avec SO_REUSEADDR pour éviter les conflits

### Option 4 : Docker (Apache + Live reload)

**Toutes les plateformes (avec bash installé) :**
```bash
# Permissions d'exécution (si nécessaire)
chmod +x dev/docker.sh dev/docker-stop.sh

# Démarrage complet
./dev/docker.sh

# Arrêt
./dev/docker-stop.sh
```

➜ **Accès aux services :**
- http://localhost:8080 (Apache)
- http://localhost:3000 (Live reload)
- http://localhost:3001 (BrowserSync)


 ### Option 5 : Docker Installation manuelle 

- docker/DockerFile :
```
FROM httpd:2.4

# Define user
ARG USER=appuser
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN groupadd -g ${GROUP_ID} ${USER} \
    && useradd -m -u ${USER_ID} -g ${GROUP_ID} ${USER}

# Change ownership of the web and log directories so the user can access them.
RUN chown -R ${USER}:${USER} /usr/local/apache2/htdocs/
RUN chown -R ${USER}:${USER} /usr/local/apache2/logs/

# Enable SSI by loading the module directly in httpd.conf.
RUN echo 'LoadModule include_module modules/mod_include.so' >> /usr/local/apache2/conf/httpd.conf

# Enable the reading of .htaccess files.
RUN sed -i 's/AllowOverride None/AllowOverride All/' /usr/local/apache2/conf/httpd.conf

# Switch to the non-root user
USER ${USER}

EXPOSE 80
```

- docker/compose.yaml :

```
services:
  apache:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: indignons-nous
    ports:
      - "8080:80"
    volumes:
      - ../:/usr/local/apache2/htdocs/
    restart: unless-stopped

  node:
    image: node:18-alpine
    container_name: live_reload
    volumes:
      - ../:/app
    working_dir: /app
    ports:
      - "3000:3000" # Access the site on this port to have live reload (html, css)
      - "3001:3001" # BrowserSync dashboard (logs, settings...)
    command: npx browser-sync start --proxy "http://apache:80" --files "**/*"
```


### Préparation production

**Toutes les plateformes (avec bash installé) :**
```bash
# Permissions d'exécution (si nécessaire - normalement fait par setup.sh)
chmod +x dev/prod.sh

# Préparer pour la production
./dev/prod.sh
```

*Note : Les permissions d'exécution sont automatiquement attribuées par `./dev/setup.sh`*

## Structure du projet

```
├── index.html              # Page d'accueil
├── global/                 # Ressources partagées (CSS, JS, SSI)
├── local/                  # Personnalisations locales
├── src/                    # Scripts PHP de génération
├── dev/                    # Outils de développement (ignoré en prod)
│   └── *.sh               # Scripts bash
├── docker/                 # Configuration Docker (ignoré en prod)
├── favicon.ico            # Icône du site
└── .htaccess              # Configuration Apache avec sécurité
```

## Technologies

- **HTML + CSS** "old school"
- **SSI** (Server-Side Includes) pour les includes
- **PHP** pour la génération des groupes
- **Python** pour le serveur de développement
- **Docker** pour l'environnement complet

## Scripts de développement

### Serveur Python
- `./dev/setup.sh` - Configuration initiale complète :
  - Génère automatiquement le serveur Python avec support SSI
  - Crée un menu de développement sans conditions SSI
  - Configure les fichiers .htaccess pour le développement
  - Prépare tous les dossiers et fichiers nécessaires
- `./dev/start.sh` - Démarrage intelligent du serveur :
  - Nettoyage automatique des anciens processus
  - Libération du port 8000 avec plusieurs tentatives
  - Vérification du bon démarrage du serveur
  - Ouverture automatique du navigateur
- `./dev/stop.sh` - Arrêt propre du serveur :
  - Détection par port et par nom de processus
  - Arrêt forcé si nécessaire
  - Vérification de la libération du port

### Docker
- `./dev/docker.sh` - Démarrage de l'environnement Docker complet
- `./dev/docker-stop.sh` - Arrêt de l'environnement Docker

*Note : Si les scripts Docker ne sont pas exécutables : `chmod +x dev/docker.sh dev/docker-stop.sh`*

### Production
- `./dev/prod.sh` - Préparation pour la production (menu SSI, .htaccess, nettoyage)

*Note : Si le script prod n'est pas exécutable : `chmod +x dev/prod.sh`*

## Ports utilisés

| Port | Service | Environnement |
|------|---------|---------------|
| 8000 | Serveur Python | Développement |
| 8080 | Apache | Docker |
| 3000 | Live reload | Docker |
| 3001 | BrowserSync | Docker |

## Prérequis

### Pour tous les environnements
- **Git** (pour cloner le projet)
- **Bash** (voir instructions Windows ci-dessous)

### Option 1 - Apache local
- **Apache** installé sur votre système
- Voir [Configuration SSI](https://github.com/10s25/site/wiki/Configuration-SSI)

### Option 2 - WAMP/MAMP
- **WAMP** (Windows) ou **MAMP** (macOS) installé
- Voir [Configuration SSI](https://github.com/10s25/site/wiki/Configuration-SSI)

### Option 3 - Serveur Python
- **Python 3.x** installé sur votre système
- **lsof** (généralement préinstallé sur Linux/macOS)

### Options 4 et 5 - Docker
- **Docker** et **Docker Compose** installés

## Dépannage

### Comment arrêter le serveur
**Méthode recommandée** : Ouvrir un nouveau terminal
```bash
# Aller dans le dossier du projet
cd ~/Bureau/site-main

# Arrêter le serveur proprement
./dev/stop.sh
```

**Alternative** : Dans le terminal où tourne le serveur, appuyer sur **Ctrl+C**

### Problèmes de port
Si vous obtenez "Address already in use" :
```bash
# Arrêter tous les serveurs
./dev/stop.sh

# Attendre quelques secondes puis redémarrer
./dev/start.sh
```

### Problèmes de permissions
**Première utilisation :** `chmod +x dev/setup.sh` est nécessaire pour lancer le setup.
Ensuite, les permissions sont automatiquement attribuées par `./dev/setup.sh`.

**Commandes chmod par script :**
```bash
# Pour le setup (obligatoire en premier)
chmod +x dev/setup.sh

# Pour les autres scripts (normalement fait automatiquement par setup.sh)
chmod +x dev/start.sh
chmod +x dev/stop.sh
chmod +x dev/prod.sh

# Pour Docker (si utilisé)
chmod +x dev/docker.sh
chmod +x dev/docker-stop.sh

# Ou tous d'un coup
chmod +x dev/*.sh
```

### Régénération complète
Si vous avez des problèmes, relancez la configuration :
```bash
./dev/setup.sh
./dev/start.sh
```

### Windows - Installation de bash (requis)
Pour utiliser ce projet sur Windows, vous devez installer bash. Choisissez une des options :

1. **Git Bash** ⭐ (le plus simple)
2. **WSL** (Windows Subsystem for Linux)
3. **MSYS2**

Voir les instructions détaillées dans la section "Développement local" ci-dessus.

