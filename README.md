# K8s cluster bootstrap and app install

[![ArgoCD Status](https://argocd.apps.blah.cloud/api/badge?name=bootstrap&revision=true)](https://argocd.apps.blah.cloud/applications/bootstrap)

## K8s cluster installed via Ansible

<https://github.com/mylesagray/rak8s>

Following on from cluster install, install apps as below.
## TL;DR

```sh
make fresh
```

## Manual Install
### Install Prometheus CRDs

```sh
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.49.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.49.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.49.0/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.49.0/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.49.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.49.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.49.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.49.0/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
```

### Bitnami Sealed Secrets

#### Install Sealed Secrets

```sh
helm upgrade --install sealed-secrets -n kube-system ./manifests/sealed-secrets -f manifests/sealed-secrets/values.yaml
```

#### Seal secrets

```sh
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/docker-creds.yaml > manifests/registry-creds/docker-creds-sealed.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/argocd-secret.yaml > manifests/argocd/templates/argocd-sealed-secret.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/argocd-github-secret.yaml > manifests/argocd/templates/argocd-github-sealed-secret.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/argocd-rak8s-secret.yaml > manifests/argocd/templates/argocd-rak8s-sealed-secret.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/traefik-dnsprovider-config.yaml > manifests/traefik/templates/traefik-dnsprovider-config-sealed.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/argocd-notifications-secret.yaml > manifests/argocd-notifications/templates/argocd-notifications-secret-sealed.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/renovate-secret.yaml > manifests/renovate/templates/renovate-sealed-secret.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/keycloak-secret.yaml > manifests/keycloak/templates/keycloak-secret-sealed.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/keycloak-postgres-secret.yaml > manifests/keycloak/templates/keycloak-postgres-secret-sealed.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/argo-workflows-sso.yaml  > manifests/argocd-workflows/templates/argo-workflows-sso-sealed.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/argo-workflows-minio.yaml  > manifests/argocd-workflows/templates/argo-workflows-minio-sealed.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/argo-workflows-minio-minio.yaml  > manifests/minio/templates/argo-workflows-minio-minio-sealed.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/cert-secret.yaml  > manifests/kube-prometheus-stack/templates/cert-secret-sealed.yaml
kubeseal --format=yaml < ~/Desktop/ArgoCD\ Secrets/cloudflare-api-token.yaml  > manifests/cert-manager/templates/cloudflare-api-token-sealed.yaml
```

#### Backup seal key

```sh
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > ~/Desktop/ArgoCD\ Secrets/sealed-secrets-master.key
```

### (Optional) Restore Bitnami SS from backup - if bad things happened...

```sh
helm upgrade --install sealed-secrets -n kube-system ./manifests/sealed-secrets -f manifests/sealed-secrets/values.yaml
kubectl delete secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key=active
kubectl apply -n kube-system -f ~/Desktop/ArgoCD\ Secrets/sealed-secrets-master.key
kubectl delete pod -n kube-system -l app.kubernetes.io/name=sealed-secrets
```

### Initialise secrets needed for bootstrap

```sh
kubectl create ns argocd
kubectl apply -f manifests/argocd-notifications/templates/
kubectl apply -f manifests/argocd-workflows/templates/
```

### Install Argo and bootstrap cluster

```sh
make install-argocd
make get-argocd-password
```

## Use

```sh
argocd login argocd.apps.blah.cloud --sso --grpc-web
#login with GitHub account or admin password from above
argocd account update-password
argocd app list
```

## Cleanup

```sh
make cleanup
```

## Todo

### Apps

* Move from traefik to traefik + cert-manager for ingress and TLS
  * Traefik ~HA mode?
    * <https://blog.deimos.fr/2018/01/23/traefik-ha-helm-chart-with-le-on-k8s/>
    * <https://github.com/MySocialApp/kubernetes-helm-chart-traefik>
  * Use cert-manager for TLS with DNS-01 challenges
  * Use IngressClass for Traefik rather than making it a default IngressClass
    * Investigate reloading Traefik when Cert-Manager changes a cert
      * <https://github.com/mmatur/traefik-cert-manager>
      * <https://www.padok.fr/en/blog/traefik-kubernetes-certmanager>
      * <https://cert-manager.io/docs/usage/ingress/>
* Move to kube-vip from metallb
  * For control plane: <https://kube-vip.io/install_static/>
  * For svc type LB: <https://kube-vip.io/usage/on-prem/#Flow>
* Add OIDC provider
  * Pinniped? <https://pinniped.dev>
* Add Renovate self-hosted
* Add Argo Events
* Add Argo Rollouts
* Investigate Argo Operator
* ARM Builds of complex tools
  * Add Istio (needs ARM builds - <https://github.com/istio/istio/issues/21094>)
  * Add Tekton (needs ARM builds - <https://github.com/tektoncd/pipeline/issues/856>)
  * Add KNative (needs ARM builds - <https://github.com/knative/serving/issues/8320>)
  * All above rely on ko builds for ARM: <https://github.com/google/ko/pull/211>

#### Ongoing

* Build ARM versions of containers I depend on
  * Do it scalably and open upstream PRs

### Monitoring

* Add cert-manager mixin <https://monitoring.mixins.dev/cert-manager/>
  * <https://gitlab.com/uneeq-oss/cert-manager-mixin>
* Add carlosedp Cluster Dashboard to Grafana

### Organisational

* Refactor namespaces
* Refactor Apps into Projects
* Deploy from tags/branches rather than master

### Security

* Remove all internal un/passwords and keys and turn into sealed secrets
* Make ArgoCD GitHub webhook authenticated
