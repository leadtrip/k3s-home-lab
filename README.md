# Kubernetes Home Lab

This repository contains configurations and scripts to set up a home lab Kubernetes cluster using K3s.

## To setup the dashboard from scratch run
1. run ./scripts/setup-dashboard.sh
2. Copy the token printed in the terminal
3. Access the dashboard at 👉 https://localhost:8443
4. Paste the token in the login screen

# Dashboard
### Start the dashboard
`kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 8443:443`

### Get a token to login to the dashboard when already setup
`./scripts/get-dashboard-token.sh`

### Go to the dashboard
https://localhost:8443/

# Sealed secrets
Sealed secrets allow us to commit secrets to github in a safe manner along with all other K8s config.
Install the controller and kubeseal as per instructions - https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file

### Create the sealed secret which you can commit to github e.g. from a file:
`kubeseal --controller-namespace kube-system --format yaml < mysql-secret.yaml > sealed-mysql-secret.yaml`

### Or pipe to avoid creating file:
`echo "apiVersion: v1\nkind: Secret\nmetadata:\n  name: my-secret\ntype: Opaque\nstringData:\n  username: myuser\n  password: mypassword" | kubeseal --controller-namespace kube-system --format yaml > sealed-my-secret.yaml`

### Apply the secret
`kubectl apply -f sealed-mysql-secret.yaml`

## MySQL database
A MySQL database is created along with a ClusterIp service to allow command line access via a temporary MySQL client pod which you can create with:
`kubectl run mysql-client --image=mysql:latest --rm -it --restart=Never --command -- mysql -h mysql -P 3306 -u myuser -pmysecretpassword mydb`
