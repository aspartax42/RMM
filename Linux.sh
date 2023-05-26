#/bin/bash

if [ "$UID" -ne 0 ]; then
  echo "Merci d'exécuter en root"
  exit 1
fi

# Principaux paramètres
tput setaf 7; read -p "Entrer l'url de téléchargement de l'agent Mesh: " MeshURL


#Installation de GO
wget https://go.dev/dl/go1.20.2.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.2.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version


#Installation de l'agent mesh
wget -O meshagent $MeshURL
chmod +x meshagent
mkdir /opt/tacticalmesh
./meshagent -install --installPath="/opt/tacticalmesh"



#Compilation de l'agent
git clone https://github.com/amidaware/rmmagent.git
cd rmmagent
env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-s -w"
cp rmmagent /usr/local/bin/



#Paramètres Supplémentaires
clear
tput bold; tput setaf 7; echo "       => Installation de l'agent RMM <=       "
tput setaf 7; read -p "Entrer l'url de l'api: " APIURL
tput setaf 7; read -p "Entrer l'ID du client RMM: " ClientID
tput setaf 7; read -p "Entrer l'ID du site clint RMM: " SiteID
tput setaf 7; read -p "Entrer le type d'agent (workstation / server): " AgentType
tput setaf 7; read -p "Entrer la clé d'authentification: " AuthKey

#Installation de l'agent RMM
./rmmagent -m install --api $APIURL --client-id $ClientID --site-id $SiteID --agent-type $AgentType --auth $AuthKey



#Creation du service
echo "[Unit]
Description=Tactical RMM Linux Agent
[Service]
Type=simple
ExecStart=/usr/local/bin/rmmagent -m svc
User=root
Group=root
Restart=always
RestartSec=5s
LimitNOFILE=1000000
KillMode=process
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/tacticalagent.service

systemctl daemon-reload
systemctl enable --now tacticalagent
