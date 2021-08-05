# K8s cluster bootstrap and app install

[![ArgoCD Status](https://argocd.apps.blah.cloud/api/badge?name=bootstrap&revision=true)](https://argocd.apps.blah.cloud/applications/bootstrap)

## Bitnami Sealed Secrets

### Install Sealed Secrets

```sh
helm upgrade --install sealed-secrets -n kube-system ./manifests/sealed-secrets -f manifests/sealed-secrets/values.yaml
```

### Seal secrets

```sh
kubeseal --format=yaml < ~/Desktop/docker-creds.yaml > manifests/registry-creds/docker-creds-sealed.yaml
kubeseal --format=yaml < ~/Desktop/argocd-secret.yaml > manifests/argocd/templates/argocd-sealed-secret.yaml
kubeseal --format=yaml < ~/Desktop/argocd-github-secret.yaml > manifests/argocd/templates/argocd-github-sealed-secret.yaml
kubeseal --format=yaml < ~/Desktop/argocd-rak8s-secret.yaml > manifests/argocd/templates/argocd-rak8s-sealed-secret.yaml
kubeseal --format=yaml < ~/Desktop/traefik-dnsprovider-config.yaml > manifests/traefik/templates/traefik-dnsprovider-config-sealed.yaml
kubeseal --format=yaml < ~/Desktop/argocd-notifications-secret.yaml > manifests/argocd-notifications/templates/argocd-notifications-secret-sealed.yaml
kubeseal --format=yaml < ~/Desktop/renovate-secret.yaml > manifests/renovate/templates/renovate-sealed-secret.yaml
kubeseal --format=yaml < ~/Desktop/keycloak-secret.yaml > manifests/keycloak/templates/keycloak-secret-sealed.yaml
kubeseal --format=yaml < ~/Desktop/keycloak-postgres-secret.yaml > manifests/keycloak/templates/keycloak-postgres-secret-sealed.yaml
kubeseal --format=yaml < ~/Desktop/argo-workflows-sso.yaml  > manifests/argocd-workflows/templates/argo-workflows-sso-sealed.yaml
kubeseal --format=yaml < ~/Desktop/argocd-workflows-minio.yaml  > manifests/argocd-workflows/templates/argocd-workflows-minio-sealed.yaml
```

### Backup seal key

```sh
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > ~/Desktop/sealed-secrets-master.key
```

## Restore Bitnami SS from backup (if bad things happened)

```sh
helm upgrade --install sealed-secrets -n kube-system ./manifests/sealed-secrets -f manifests/sealed-secrets/values.yaml
kubectl delete secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key=active
kubectl apply -n kube-system -f ~/Desktop/sealed-secrets-master.key
kubectl delete pod -n kube-system -l app.kubernetes.io/name=sealed-secrets
```

## Install Argo and bootstrap cluster

```sh
make install-argocd
make get-argocd-password
make check-argocd-ready
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

* Build ARM versions of containers I depend on
  * Do it scalably and open upstream PRs
* Add Argo Workflows
* Add Argo Events
* Add Argo Rollouts
* Investigate Argo Operator
* Add kube-prometheus
* Add Renovate self-hosted
* Add OIDC provider
* Move to kube-vip from metallb
* ARM Builds of complex tools
  * Add Istio (needs ARM builds - <https://github.com/istio/istio/issues/21094>)
  * Add Tekton (needs ARM builds - <https://github.com/tektoncd/pipeline/issues/856>)
  * Add KNative (needs ARM builds - <https://github.com/knative/serving/issues/8320>)
  * All above rely on ko builds for ARM: <https://github.com/google/ko/pull/211>
* Move from traefik to nginx + cert-manager for ingress and TLS
  * Traefik HA mode?
    * <https://blog.deimos.fr/2018/01/23/traefik-ha-helm-chart-with-le-on-k8s/>
    * <https://github.com/MySocialApp/kubernetes-helm-chart-traefik>

### Organisational

* Refactor namespaces
* Refactor App hierarchy
* Refactor Apps into Projects
* Use sync waves
* Deploy from tags/branches rather than master

### Security

* Remove all internal un/passwords and keys and turn into sealed secrets
* Make ArgoCD GitHub webhook authenticated
