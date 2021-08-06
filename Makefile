.PHONY: install-argocd get-argocd-password proxy-argocd-ui check-argocd-ready

list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

get-argocd-password:
	kubectl wait --for=condition=available deployment -l "app.kubernetes.io/name=argocd-server" -n argocd --timeout=300s
	kubectl get secret argocd-initial-admin-secret -o json | jq -r .data.password | base64 -d

install-argocd:
	kubectl create ns argocd || true
	kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/appproject-crd.yaml
	kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/application-crd.yaml
	helm upgrade --install argocd -n argocd ./manifests/argocd -f manifests/argocd/values.yaml

install-cert-manager:
	helm repo add jetstack https://charts.jetstack.io
	kubectl create ns cert-manager
	kubectl label ns cert-manager cert-manager.k8s.io/disable-validation=true
	kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.14.0/cert-manager.crds.yaml
	helm upgrade --install cert-manager --n cert-manager --version v0.14.0 jetstack/cert-manager
	kubectl apply -f resources/letsencrypt-issuer.yaml

cleanup:
	helm delete argocd || true
	kubectl delete appprojects.argoproj.io --all
	kubectl delete applications.argoproj.io --all
	kubectl delete -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/appproject-crd.yaml
	kubectl delete -f https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/application-crd.yaml
	kubectl delete ns argocd
	kubectl delete ns infra
	kubectl delete ns cheese
	kubectl delete ns ingress
	kubectl delete ns kubernetes-dashboard
	kubectl delete ns velero
	kubectl delete ns registry-creds-system