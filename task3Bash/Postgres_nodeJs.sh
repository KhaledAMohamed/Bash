#!/bin/bash

alldependinceies() {
  sudo yum install -y curl dirmngr yum-utils nodejs postgresql git npm
  curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash -
  npm install dotenv express pg pine sequelize swagger-ui-express
}

change_ip() {
  sudo tee -a /etc/sysconfig/network-scripts/ifcfg-ens3 <<EOF
DEVICE=ens3
TYPE=Ethernet
BOOTPROTO=none
ONBOOT=yes
IPADDR=192.168.66.128
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
EOF

  ip_regex='([0-9]{1,3}\.){3}[0-9]{1,3}'
  ip_address=$(ifconfig | grep -oP "$ip_regex" | head -n 1)
}

user() {
  sudo useradd -m node
  sudo passwd node
  sudo usermod -aG wheel node
}

postgres() {
  systemctl start postgresql
  postgres psql -c "CREATE DATABASE node"
  postgres psql -c "CREATE USER khaled  WITH PASSWORD '123456'"
  postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE node TO node"
}

git_clone() {
  git clone https://github.com/omarmohsen/pern-stack-example.git
  cd pern-stack-example
}


run() {
  cd ui
  npm install
  npm run build

  cd ..
  sed -i "/if (environment === 'demo') {/,/};/c \\
if (environment === 'demo') { \\
    ENVIRONMENT_VARIABLES = { \\
        'process.env.HOST': JSON.stringify('192.168.66.128'), \\
        'process.env.USER': JSON.stringify('node'), \\
        'process.env.DB': JSON.stringify('node'), \\
        'process.env.DIALECT': JSON.stringify('postgres'), \\
        'process.env.PORT': JSON.stringify('5432'), \\
        'process.env.PG_CONNECTION_STR': JSON.stringify('postgres://node:node@192.168.66.128:5432/node') \\
    }; \\
}" api/webpack.config.js

  export PG_CONNECTION_STR=postgres://node:node@192.168.66.128:5432/node
	
  cd ui
  ENVIRONMENT=demo npm run build
  cd ..
  cp -r ui api
  cd api && npm start
}

alldependinceies
change_ip
user
postgres
git_clone
run
