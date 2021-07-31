#!/usr/bin/env bash

brew install kubectx
brew install fzf
brew install dty1er/tap/kubecolor
brew install helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
brew install skaffold

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "Kubernetes tools was installed in Ubuntu"
echo "please re-login again"

chmod -x ./2-tool-mac.sh
