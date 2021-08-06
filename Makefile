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
	helm delete -n argocd argocd || true
	helm delete -n kube-system sealed-secrets || true
	kubectl get apiservice | grep False | awk '{print $1}' | xargs -I {} kubectl delete apiservice {}
	kubectl get applications.argoproj.io -o name | sed -e 's/.*\///g' | xargs -I {} kubectl patch applications.argoproj.io {} -p '{"metadata":{"finalizers":[]}}' --type=merge
	kubectl get appprojects.argoproj.io -o name | sed -e 's/.*\///g' | xargs -I {} kubectl patch appprojects.argoproj.io {} -p '{"metadata":{"finalizers":[]}}' --type=merge
	kubectl delete appprojects.argoproj.io --all || true
	kubectl delete applications.argoproj.io --all || true
	kubectl delete crd applications.argoproj.io || true
	kubectl delete crd appprojects.argoproj.io || true
	kubectl delete ns argocd || true
	kubectl delete ns infra || true
	kubectl delete ns buildkit || true
	kubectl delete ns buildkit-emu || true
	kubectl delete ns cheese || true
	kubectl delete ns ingress || true
	kubectl delete ns keycloak || true
	kubectl delete ns kibana || true
	kubectl delete ns elasticsearch || true
	kubectl delete ns knative || true
	kubectl delete ns logging || true
	kubectl delete ns minio || true
	kubectl delete ns monitoring || true
	kubectl delete ns qemu-binfmt || true
	kubectl delete ns quake || true
	kubectl delete ns renovate || true
	kubectl delete ns storage || true
	kubectl delete ns kubernetes-dashboard || true
	kubectl delete ns velero || true
	kubectl delete ns auth || true
	kubectl delete ns registry-creds-system || true
	kubectl delete crd --all || true
	kubectl delete all -l app.kubernetes.io/managed-by=Helm -A || true