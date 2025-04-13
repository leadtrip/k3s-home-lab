# Kubernetes Home Lab
This repository contains configurations and scripts to set up a home lab Kubernetes cluster using K3s.
## Dashboard
### To setup the dashboard from scratch run
1. run ./scripts/setup-dashboard.sh
2. Copy the token printed in the terminal
3. Access the dashboard at 👉 https://localhost:8443
4. Paste the token in the login screen

### Start the dashboard
`kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 8443:443`

### Get a token to login to the dashboard when already setup
`./scripts/get-dashboard-token.sh`

### Go to the dashboard
https://localhost:8443/

## [Sealed secrets](https://github.com/bitnami-labs/sealed-secrets)
Sealed secrets allow us to commit secrets to github in a safe manner along with all other K8s config.
Install the controller and kubeseal as per instructions - https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file

### Create the sealed secret which you can commit to github e.g. from a file:
`kubeseal --controller-namespace kube-system --format yaml < mysql-secret.yaml > sealed-mysql-secret.yaml`

### Or pipe to avoid creating file:
`echo "apiVersion: v1\nkind: Secret\nmetadata:\n  name: my-secret\ntype: Opaque\nstringData:\n  username: myuser\n  password: mypassword" | kubeseal --controller-namespace kube-system --format yaml > sealed-my-secret.yaml`

### Apply the secret
`kubectl apply -f sealed-mysql-secret.yaml`

## MySQL database
A MySQL database is created along with a ClusterIp service to allow command line access via a temporary MySQL client pod which you can create with\
`kubectl run mysql-client --image=mysql:latest --rm -it --restart=Never --command -- mysql -h mysql-clusterip -P 3306 -u myuser -pmysecretpassword mydb`

## [Metallb](https://metallb.io/)
#### A load balancer that can be used on bare metal kubernetes deployments that allows use of LoadBalancer
Install & configuration (check current version in url)

`kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml` \
We're using Layer 2 config, follow the docs to create an [IPAddressPool](configs/metallb/metallb-ip-address-pool.yaml) and [L2Advertisement](configs/metallb/metallb-l2-advertisement.yaml) manifest.

## Apps
At this stage we're accessing an app's endpoint using the external IP given by metallb to the associated service.\
To get the app's external IP, get the service filtering by the service label e.g.\
`kc get services -o wide -l app=person-service` \
Then hit the endpoint like.\
`curl http://192.168.86.200:8000/people`
#### Person service
A [simple spring boot](https://github.com/leadtrip/personservice) app

A few of the endpoints offered are:\
http://EXTERNAL_ID:8080/people \
http://EXTERNAL_ID:8080/people/1 \
curl -i -H "Content-Type:application/json" -d '{"firstName": "Roger", "lastName": "Black"}' http://EXTERNAL_ID:8080/people
#### Spring GraphQL server
A [spring boot graphql](https://github.com/leadtrip/sb-graphql-server) server
`kc get services -o wide -l app=sb-graphql-server`
Fire up the graphql playground e.g. `http://192.168.86.203:8181/graphiql?path=/graphql` \
Or use curl: \
```
curl -X POST \
     -H "Content-Type: application/json" \
     -d '{"query": "query personDetails {\n  personById(id: 1) {\n    id\n    firstName\n    lastName\n  }\n}"}' \
     http://192.168.86.203:8181/graphql
```
