#!/bin/bash

set -x

# Install rsync if it's not already installed
command -v rsync &> /dev/null || sudo apt-get install -y rsync

# # Install Garden if it's not already installed
command -v garden &> /dev/null || (curl -sSL https://github.com/garden-io/garden/releases/download/0.13.0/garden-0.13.0-linux-amd64.tar.gz | tar xz && \
sudo mv linux-amd64/* /usr/local/bin)

# K3s is already installed in Killercoda need Kubeconfig to remove traefik
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm -n kube-system uninstall traefik && helm -n kube-system uninstall traefik-crd
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

# Wait for traefik to be removed
sleep 5

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

# Fix docker image names
sudo usermod -aG docker ubuntu
sudo systemctl restart docker

# This tells killercoda that the background is finished
echo done > /tmp/background0