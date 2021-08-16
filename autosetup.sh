#!/bin/bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "autosetup.sh must be run as root!"
    exit
fi

set -e


echo "STEP 1: Installing Rust / 正在安裝 Rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

echo "STEP 2: Compiling geph4-exit / 正在編譯 geph4-exit"
cargo install --locked geph4-exit

echo "STEP 3: Creating config file / 創建設置文件"
tee ~/geph4-exit.toml << EOF
# Where to listen for incoming connections. Change 8814 to whatever port you like
sosistab_listen = "[::]:8814"
# Where to store secret key
secret_key = "$HOME/geph4-exit.key"
EOF

echo "STEP 4: Creating systemd unit / 啓用 systemd 服務"
sudo tee /etc/systemd/system/geph4-exit.service << EOF 
[Unit]
Description=Geph4 bridge service.
[Service]
Type=simple
Restart=always
ExecStart=$(which geph4-exit) --config $HOME/geph4-exit.toml
LimitNOFILE=65536
User=$(whoiam)
[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 /etc/systemd/system/geph4-exit .service
sudo systemctl enable geph4-exit
sudo systemctl daemon-reexec
sudo systemctl restart geph4-exit

echo "STEP 5: Waiting for public key..."
sudo journalctl | grep geph | grep listening | head