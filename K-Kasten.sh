#!/usr/bin/env bash
helm repo add kasten https://charts.kasten.io/
helm repo update

kubectl get volumesnapshotclass | grep csi-hostpath-snapclass
retval2=$?
if [ ${retval2} -eq 0 ]; then
kubectl annotate volumesnapshotclass csi-hostpath-snapclass \
    k10.kasten.io/is-snapshot-class=true
fi

kubectl get volumesnapshotclass | grep csi-rbdplugin-snapclass
retval3=$?
if [ ${retval3} -eq 0 ]; then
kubectl annotate volumesnapshotclass csi-rbdplugin-snapclass \
    k10.kasten.io/is-snapshot-class=true
fi

curl https://docs.kasten.io/tools/k10_primer.sh | bash
rm k10primer.yaml

# Install Kasten
kubectl create namespace kasten-io
helm install k10 kasten/k10 --namespace=kasten-io \
--set services.securityContext.runAsUser=0 \
--set services.securityContext.fsGroup=0 \
--set prometheus.server.securityContext.runAsUser=0 \
--set prometheus.server.securityContext.runAsGroup=0 \
--set prometheus.server.securityContext.runAsNonRoot=false \
--set prometheus.server.securityContext.fsGroup=0 \
--set global.persistence.size=40G \
--set global.persistence.storageClass=csi-hostpath-sc \
--set injectKanisterSidecar.enabled=true \
--set auth.tokenAuth.enabled=true \
--set externalGateway.create=true \
--set ingress.create=true

# define NFS storage
kubectl get csidrivers.storage.k8s.io | grep nfs
retval4=$?
if [ ${retval4} -eq 0 ]; then
cat <<EOF | kubectl apply -n kasten-io -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
   name: kastenbackup-pvc
spec:
   storageClassName: nfs-csi
   accessModes:
      - ReadWriteMany
   resources:
      requests:
         storage: 20Gi
EOF
fi

echo "Following is login token"
sa_secret=$(kubectl get serviceaccount k10-k10 -o jsonpath="{.secrets[0].name}" --namespace kasten-io)
kubectl get secret $sa_secret --namespace kasten-io -ojsonpath="{.data.token}{'\n'}" | base64 --decode > k10-k10.token
echo "" >> k10-k10.token
cat k10-k10.token
echo

EXTERNALIP=`kubectl -n kasten-io get ingress | awk '{print $4}' | tail -n 1`

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "Confirm kasten is running with kubectl get pods --namespace kasten-io"
echo "kubectl --namespace kasten-io port-forward --address 0.0.0.0 service/gateway 8080:8000"
echo "Open your browser http://${LOCALIPADDR}:8080/k10/#/"
echo "or"
echo "Open http://${EXTERNALIP}/10 from local browser"
echo "then input login token"
echo "Note:"
echo 

