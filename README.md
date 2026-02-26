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

## Monitoring/observability 
Prometheus and Grafana has been setup by terraform in this [project](https://github.com/leadtrip/terraform-playground/tree/master/kubernetes-local/monitoring-tools)\
`kubectl port-forward svc/kube-prometheus-stack-prometheus 9090 -n monitoring`\
`kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring`

Then access the UIs at\
http://localhost:9090/ \
http://localhost:3000/

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
You need to disable the bundled servicelb load balancer first.\
Add (or create the file if need be) the following to `/etc/rancher/k3s/config.yaml`
then restart k3s
```yaml
disable:
- servicelb
```
`sudo systemctl restart k3s`\

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
http://EXTERNAL-IP:8080/people \
http://EXTERNAL-Ip:8080/people/1 \
`curl -i -H "Content-Type:application/json" -d '{"firstName": "Roger", "lastName": "Black"}' http://EXTERNAL_ID:8080/people`
#### Spring GraphQL server
A [spring boot graphql](https://github.com/leadtrip/sb-graphql-server) server\
First off get the EXTERNAL-IP with:\
`kc get services -o wide -l app=sb-graphql-server`\
Fire up the graphql playground e.g. `http://EXTERNAL-IP:8181/graphiql?path=/graphql` \
Or use curl: \
```
curl -X POST \
     -H "Content-Type: application/json" \
     -d '{"query": "query personDetails {\n  personById(id: 1) {\n    id\n    firstName\n    lastName\n  }\n}"}' \
     http://EXTERNAL-IP:8181/graphql
```
#### Spring boot gRPC server
A [spring boot gRPC server](https://github.com/leadtrip/sb-grpc-server) app\
You can hit this server with the micronaut gRPC client app mentioned below or maybe with grpcurl as per below, first you'll need the CLUSTER-IP\
`k get svc -o wide -l app=sb-grpc-server`\
Then...\
`grpcurl -d '{"name": "Mike"}' -plaintext CLUSTER-IP:50052 wood.mike.SimpleService.sayHi`

#### Micronaut gRPC client
A [micronaut gRPC client](https://github.com/leadtrip/mn-grpc-client) app that talks to the spring boot gRPC server\
Get the EXTERNAL-IP with:\
`k get svc -o wide -l app=mn-grpc-client`\
Send a curl request:\
`curl EXTERNAL-IP:8099/api/sayHi/bob`\
The final part of the url, bob as above can be anything.\

