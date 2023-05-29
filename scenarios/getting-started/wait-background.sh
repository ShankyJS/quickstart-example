#!/bin/bash

# waits for background init to finish

rm $0

clear

echo -n "Initializing Scenario, installing Garden 🌸, K8s and Nginx 🔨"
while [ ! -f /ks/.k8sfinished ]; do
    echo -n '.'
    sleep 1;
done;
echo " done 🚀"

echo