#!/usr/bin/env bash

#########################################################

#########################################################

#Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s


#Install Metallb
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
docker network inspect -f '{{.IPAM.Config}}' kind
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.18.255.200-172.18.255.250
EOF

# metric server
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# Modified componets.yaml
kubectl apply -f components.yaml

# Kuberntes Dashboard

kubectl create namespace kubernetes-dashboard
mkdir certs
cd certs
openssl genrsa -out dashboard.key 2048
cat <<EOF> openssl.conf
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = VA
L = Somewhere
O = MyOrg
OU = MyOU
CN = MyServerName

[v3_req]
subjectAltName = @alt_names

[alt_names]
IP.1 = 127.0.0.1
DNS.1 = 127.0.0.1
EOF
openssl req -new -x509 -nodes -days 365 -key dashboard.key -out dashboard.crt -config openssl.conf
kubectl delete secret kubernetes-dashboard-certs -n kubernetes-dashboard
kubectl create secret generic kubernetes-dashboard-certs --from-file=dashboard.key --from-file=dashboard.crt -n kubernetes-dashboard
cd ..

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Dashboard service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: dashboard-service-lb
  namespace: kubernetes-dashboard
spec:
  type: LoadBalancer
  ports:
    - name: dashboard-service-lb
      protocol: TCP
      port: 443
      nodePort: 30085
      targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
EOF

kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}" > dashboard.token
echo "" >> dashboard.token
cat dashboard.token 

# Expoert kubeconfig
kubectl config view --raw > Your_kind_kubeconfig-`hostname`
echo "" >>Your_kind_kubeconfig-`hostname`
#kubectl config use-context kind-k10-demo
kubectl config get-contexts

EXTERNALIP=`kubectl -n kubernetes-dashboard get service dashboard-service-lb| awk '{print $4}' | tail -n 1`
echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "you can access Kubernetes dashboard"
echo "Option 1"
echo "then access https://${EXTERNALIP}/#/login from local browser"
echo "Option 2"
echo "run kubectl port-forward --address 0.0.0.0 svc/dashboard-service-lb 8082:443 -n kubernetes-dashboard"
echo "then access https://$LOCALIPADDR}:8082/#/login"
echo "option 3"
echo "with kubectl proxy"
echo "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login"

chmod -x ./3-configk8s-mac.sh
