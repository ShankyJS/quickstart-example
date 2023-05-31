#!/bin/bash

# Install rsync if it's not already installed
command -v rsync &> /dev/null || sudo apt-get install -y rsync

# # Install Garden if it's not already installed
command -v garden &> /dev/null || (curl -sSL https://github.com/garden-io/garden/releases/download/0.13.0/garden-0.13.0-linux-amd64.tar.gz | tar xz && \
sudo mv linux-amd64/* /usr/local/bin)

/usr/local/bin/k3s-killall.sh # <- Because this lab uses k3s by default, this command is needed for me to create a new cluster with the options I need.

# Start k3s server with host Docker iamge support and Traefik ingress controller disabled
nohup sudo k3s server --docker --disable=traefik --write-kubeconfig-mode=644 --snapshotter native > /dev/null 2>&1 &

# Wait for traefik to be deployed before continuing
sleep 5

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml # This is needed in order to run Helm commands
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

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
sleep 5 # Wait for Traefik jobs to be created
kubectl wait --for=condition=complete --timeout=60s -n kube-system job/helm-delete-traefik-crd
kubectl wait --for=condition=complete --timeout=60s -n kube-system job/helm-delete-traefik

# This tells killercoda that the background is finished
echo done > /tmp/background0