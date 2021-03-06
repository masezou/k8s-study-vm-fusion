#!/usr/bin/env bash

# Configure default users
#Backup Admin
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backupadmin
  namespace: default
EOF
sa_secret=$(kubectl get serviceaccount backupadmin -o jsonpath="{.secrets[0].name}")
kubectl get secret $sa_secret  -ojsonpath="{.data.token}{'\n'}" | base64 --decode > backupadmin.token
echo "" >> backupadmin.token
kubectl get serviceaccounts
kubectl get serviceaccounts backupadmin -o yaml

kubectl create clusterrolebinding backupadmin-rolebinding --clusterrole=k10-admin  --serviceaccount=default:backupadmin

#Backup Basic
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backupbasic
  namespace: default
EOF
sa_secret=$(kubectl get serviceaccount backupbasic -o jsonpath="{.secrets[0].name}")
kubectl get secret $sa_secret  -ojsonpath="{.data.token}{'\n'}" | base64 --decode > backupbasic.token
echo "" >> backupbasic.token
kubectl get serviceaccounts
kubectl get serviceaccounts backupbasic -o yaml

kubectl create clusterrolebinding backupbasic-rolebinding --clusterrole=k10-basic  --serviceaccount=default:backupbasic

#Backup View
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backupview
  namespace: default
EOF
sa_secret=$(kubectl get serviceaccount backupview -o jsonpath="{.secrets[0].name}")
kubectl get secret $sa_secret  -ojsonpath="{.data.token}{'\n'}" | base64 --decode > backupview.token
echo "" >> backupview.token
kubectl get serviceaccounts
kubectl get serviceaccounts backupview -o yaml

kubectl create clusterrolebinding backupview-rolebinding --clusterrole=k10-config-view  --serviceaccount=default:backupview


# Configure local minio
AWS_ACCESS_KEY_ID=` echo -n "minioadminuser" | base64`
AWS_SECRET_ACCESS_KEY_ID=` echo -n "minioadminuser" | base64`

cat << EOF | kubectl -n kasten-io create -f -
apiVersion: v1
data:
  aws_access_key_id: ${AWS_ACCESS_KEY_ID}
  aws_secret_access_key: ${AWS_SECRET_ACCESS_KEY_ID}
kind: Secret
metadata:
  name: k10-s3-secret
  namespace: kasten-io
type: secrets.kanister.io/aws
EOF
cat << EOF | kubectl -n kasten-io create -f -
apiVersion: config.kio.kasten.io/v1alpha1
kind: Profile
metadata:
  name: minio-profile
  namespace: kasten-io
spec:
  type: Location
  locationSpec:
    credential:
      secretType: AwsAccessKey
      secret:
        apiVersion: v1
        kind: Secret
        name: k10-s3-secret
        namespace: kasten-io
    type: ObjectStore
    objectStore:
      name: miniobucket
      objectStoreType: S3
      endpoint: 'https://${LOCALIPADDR}:9000'
      skipSSLVerify: true
      region: us-east-1
EOF
sleep 5
kubectl -n kasten-io get profiles.config.kio.kasten.io

