# Webapp Helm Chart

A production-ready, opinionated Helm chart for deploying containerized
web applications on Kubernetes with built-in support for security
hardening, autoscaling, ingress, and GitOps workflows via ArgoCD.

------------------------------------------------------------------------

## 🚀 Overview

This chart provides a standardized way to deploy web applications with:

-   Deployment + Service + Ingress
-   ServiceAccount + RBAC (Role + ClusterRole optional)
-   Image pull secrets (e.g. GHCR)
-   Horizontal Pod Autoscaling (HPA)
-   ConfigMaps and environment variables
-   Optional SealedSecrets integration
-   Pod + container security hardening
-   Node scheduling constraints (nodeSelector, affinity, tolerations)

Designed for GitOps environments (ArgoCD compatible).

------------------------------------------------------------------------

## 🚀 ArgoCD Example

``` yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: webapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://john-ghatas.github.io/helmhub
    chart: webapp
    targetRevision: 1.1.7
  destination:
    server: https://kubernetes.default.svc
    namespace: webapps
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

------------------------------------------------------------------------

## ⚙️ Key Values

### App

-   `appName`: suffix for resource naming

### Image

-   repository / tag / pullPolicy

### Image Pull Secrets

-   used for GHCR/private registries

### Ingress

-   cert-manager supported
-   TLS optional

### Autoscaling

-   HPA enabled

### Security

-   restricted container permissions
-   seccomp runtime default

------------------------------------------------------------------------

## 🧱 Naming Convention

All resources:

    {{ fullname }}-{{ appName }}

Example:

    webapp-bastionix-app-sa

------------------------------------------------------------------------

## 🔐 Security Model

-   SealedSecrets for secrets
-   RBAC scoped per namespace
-   No plaintext secrets in Helm

------------------------------------------------------------------------

## 🧠 Design Philosophy

-   Predictable over dynamic
-   Instance-scoped resources
-   GitOps-first
-   Minimal runtime mutation


---

## ⚙️ Full values.yaml reference

```yaml
appName: app

image:
  repository: nginx
  tag: latest
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: ghcr-pull-secret

service:
  type: ClusterIP
  port: 80
  targetPort: 80

ingress:
  enabled: true
  className: nginx
  host: example.local
  path: /
  pathType: Prefix
  tls:
    enabled: false
    secretName: ""

env: {}

persistence:
  enabled: false

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 3
  targetCPUUtilizationPercentage: 70

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

containerSecurity:
  enabled: true
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL

seccompProfile:
  enabled: true
  type: RuntimeDefault

sealed:
  enabled: false
  name: my-secret
  data: {}

configmaps: {}

nodeSelector: {}

affinity: {}

tolerations: []
```

---

## 🧪 Troubleshooting

### ❌ ImagePullBackOff (GHCR / 401 Unauthorized)

Symptoms:
- failed to fetch anonymous token
- 401 Unauthorized

Fix:
- ensure imagePullSecrets exists
- ensure ServiceAccount is used by pod
- restart deployment after adding secret

```bash
kubectl rollout restart deployment <name>
```

---

### ❌ ServiceAccount not used

Check:
```bash
kubectl get pod <pod> -o jsonpath='{.spec.serviceAccountName}'
```

Fix:
- ensure `serviceAccountName` matches Helm template output

---

### ❌ SealedSecret not creating Secret

Check:
```bash
kubectl get sealedsecret
kubectl get secret
```

Fix:
- ensure sealed-secrets controller is installed
- ensure namespace matches template

---

### ❌ RBAC not applied

Check:
```bash
kubectl auth can-i get pods --as system:serviceaccount:<ns>:<sa>
```

Fix:
- verify RoleBinding / ClusterRoleBinding subject name
