#!/bin/bash

echo "We are doing the heavy lifting; a K8s cluster is being created. This will take a few minutes."

while true; do
    if [ -f "/ks/.k8sfinished" ]; then
        echo "Background tasks are finished"
        break
    fi
    sleep 0.5  # Adjust the sleep duration as needed
done
