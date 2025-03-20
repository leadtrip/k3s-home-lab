# Kubernetes Home Lab

This repository contains configurations and scripts to set up a home lab Kubernetes cluster using K3s.

## To setup the dashboard from scratch run
1. run ./scripts/setup-dashboard.sh
2. Copy the token printed in the terminal
3. Access the dashboard at 👉 https://localhost:8443
4. Paste the token in the login screen

# Dashboard
### Start the dashboard
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 8443:443

### Get a token to login to the dashboard when already setup
./scripts/get-dashboard-token.sh

### Go to the dashboard
https://localhost:8443/

# The project uses sealed secrets
Install the controller and kubeseal as per instructions - https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file

### Create the sealed secret which you can commit to github e.g.
kubeseal --controller-namespace kube-system --format yaml < mysql-secret.yaml > sealed-mysql-secret.yaml
