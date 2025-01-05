#!/bin/bash

set -e

read -p "you are $USER, and the ssh key will be generated only for you. (pres any key to continue)"
read -p "ssh server ip: " ssh_ip
read -p "ssh server port: " ssh_port
read -p "ssh server user: " ssh_user

random=$((RANDOM + 2000))
read -p "remote port to use for reverse ssh [enter for $random]: " remote_port
remote_port=${remote_port:-$random}

read -p "host ssh port [default 22]: " host_ssh_port
host_ssh_port=${host_ssh_port:-22}

while true; do
    unset use_autossh
    read -p "want to use autossh library? (autossh library will be installed with apt if you choose y) [y/N]: " use_autossh
    use_autossh=${use_autossh:-n}

    if [[ "$use_autossh" == "y" || "$use_autossh" == "n" || "$use_autossh" == "N" ]]; then
        break
    else
        echo "invalid input. please type 'y' or 'n'."
    fi
done

exec_start="/usr/bin/ssh -N -R $remote_port:localhost:$host_ssh_port $ssh_user@$ssh_ip -p $ssh_port"

if [[ "$use_autossh" == "y" ]]; then
	apt install autossh
	exec_start="/usr/bin/autossh -M 0 -N -R $remote_port:localhost:$host_ssh_port $ssh_user@$ssh_ip -p $ssh_port"
fi

# =============================================================

ssh-keygen

ssh-copy-id -p $ssh_port $ssh_user@$ssh_ip

sudo tee /etc/systemd/system/auto-reverse-ssh-tunnel.service > /dev/null <<EOL
[Unit]
Description=AutoSSH tunnel Service
After=network.service

[Service]
User=$USER
ExecStart=$exec_start

Restart=on-failure
RestartSec=120
TimeoutStartSec=5

[Install]
WantedBy=multi-user.target

EOL

sudo systemctl daemon-reload
sudo systemctl enable auto-reverse-ssh-tunnel
sudo systemctl start auto-reverse-ssh-tunnel
