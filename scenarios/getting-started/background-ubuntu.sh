#!/bin/bash

# Install rsync if it's not already installed
command -v rsync &> /dev/null || sudo apt-get install -y rsync

# # Install Garden if it's not already installed
command -v garden &> /dev/null || (curl -sSL https://github.com/garden-io/garden/releases/download/0.13.0/garden-0.13.0-linux-amd64.tar.gz | tar xz && \
sudo mv linux-amd64/* /usr/local/bin)

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin

# Download k3s if it's not already installed
if [ ! -f "./k3s" ]; then
    wget -O k3s https://github.com/k3s-io/k3s/releases/download/v1.27.1%2Bk3s1/k3s
    chmod +x k3s
else
    # Check if k3s is already running and stop it
    if ps aux | grep '[k]3s server' > /dev/null; then
        sudo kill $(ps aux | grep '[k]3s server' | awk '{print $2}')
    fi
fi

# Start k3s server with host Docker iamge support and Traefik ingress controller disabled
nohup sudo k3s server --docker --disable=traefik --write-kubeconfig-mode=644 --snapshotter native > /dev/null 2>&1 &

# Copy k3s config to user's home directory
mkdir -p ~/.kube
sleep 5
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

git clone https://github.com/garden-io/quickstart-example.git && cd quickstart-example
git config --global --add safe.directory '*'

# Do not install NGINX ingress controller
sed -i 's/\(providers:\)/\1\n  - name: local-kubernetes\n    environments: [local]\n    namespace: ${environment.namespace}\n    defaultHostname: ${var.base-hostname}\n    setupIngressController: null/' project.garden.yml

# Update the garden.yml file for the vote container
sed -i 's/servicePort: 80/nodePort: 30000/' vote/garden.yml
sed -i 's/vote.${var.base-hostname}/http:\/\/localhost:30000/' vote/garden.yml
sed -i 's/hostname:/linkUrl:/' vote/garden.yml

# Remove ingress blocks from result and api containers
sed -i '/ingresses:/, /hostname: result.\${var.base-hostname}/d' api/garden.yml result/garden.yml

# When you use --disable=traefik you need to wait for the traefik CRDs to be deleted before you can proceed.
sleep 15 # Wait for Traefik jobs to be created
kubectl wait --for=condition=complete --timeout=60s -n kube-system job/helm-delete-traefik-crd
kubectl wait --for=condition=complete --timeout=60s -n kube-system job/helm-delete-traefik

# This tells killercoda that the background is finished
echo done > /tmp/background0


