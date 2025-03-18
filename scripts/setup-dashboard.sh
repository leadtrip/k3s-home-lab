#!/bin/bash

# Exit on error
set -e

echo "Deploying Kubernetes Dashboard..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v3.0.0/aio/deploy/recommended.yaml

echo "Creating ServiceAccount and ClusterRoleBinding..."
kubectl apply -f configs/admin-user.yaml
kubectl apply -f configs/admin-user-role.yaml

echo "Retrieving login token..."
TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user)
echo "Use this token to log in:"
echo "$TOKEN"

echo "Forwarding port 8443 to access the dashboard..."
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 8443:443
