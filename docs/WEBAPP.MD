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
-   Namespace-level network isolation (NetworkPolicy)
-   Node scheduling constraints (nodeSelector, affinity, tolerations)

Designed for GitOps environments (ArgoCD compatible).

------------------------------------------------------------------------

## 🚀 ArgoCD Example

```yaml
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
-   Default-deny network policies

------------------------------------------------------------------------

## 🧱 Naming Convention

All resources follow a predictable, structured pattern to avoid naming collisions across microservices:

```text
{{ fullname }}-{{ appName }}-{{ resourceType }}
```

**Example Output (App Name: `bastionix-app`):**
- **ServiceAccount:** `webapp-bastionix-app-sa`
- **Deployment:** `webapp-bastionix-app-deploy`
- **Service:** `webapp-bastionix-app-svc`
- **NetworkPolicy:** `webapp-bastionix-app-netpol`

------------------------------------------------------------------------

## 🔐 Security Model

-   **Zero Root Privileges**: Enforces execution as UID `1000` with strict root execution blocks.
-   **Immutability**: Read-only root container filesystems to mitigate arbitrary runtime manipulation.
-   **Kernel Isolation**: Drops `ALL` Linux capabilities and enforces `RuntimeDefault` seccomp profiles to neutralize host system call escapes.
-   **Network Isolation**: Integrated toggleable `NetworkPolicy` to dynamically block lateral cluster traffic.
-   **Secret Hygiene**: SealedSecrets engine integration ensures no raw, plaintext secrets are ever checked into your Git repository.
-   **RBAC Scoping**: Deeply scoped namespace permissions using automated ServiceAccount tokens.

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

networkPolicy:
  enabled: true
  allowOnlyFromIngress: false
  ingressNamespace: "ingress-nginx"
  annotations: {}

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

## 🛠️ Deep-Dive Architecture Components

### 1. Ingress Configuration (`templates/ingress.yaml`)
Handles external SSL termination and interfaces natively with `cert-manager`. Dynamically binds the correct internal service port via values mapping:
```yaml
spec:
  rules:
    - host: {{ .Values.ingress.host }}
      http:
        paths:
          - path: {{ .Values.ingress.path | default "/" }}
            backend:
              service:
                name: {{ include "helm-base.fullname" . }}-{{ .Values.appName }}
                port:
                  number: {{ .Values.service.port }}
```

### 2. Network Policy Isolation (`templates/networkpolicy.yaml`)
Blocks raw east-west traffic. Listens precisely on the defined application target port or internal service port to map seamlessly behind the cluster ingress controllers:
```yaml
spec:
  podSelector:
    matchLabels:
      app: {{ include "helm-base.fullname" . }}-{{ .Values.appName }}
  ingress:
    - ports:
        - protocol: TCP
          port: {{ .Values.service.targetPort | default .Values.service.port }}
```

### 3. Ephemeral RAM Mounting for Read-Only Filesystems
When `containerSecurity.readOnlyRootFilesystem` is active, your deployment template should mount local writable memory caches to prevent container crashing:
```yaml
volumeMounts:
  - name: tmp-volume
    mountPath: /tmp
volumes:
  - name: tmp-volume
    emptyDir: {}
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
kubectl rollout restart deployment <deployment-name>
```

---

### ❌ ServiceAccount not used

Check:
```bash
kubectl get pod <pod-name> -o jsonpath='{.spec.serviceAccountName}'
```

Fix:
- ensure `serviceAccountName` matches Helm template output (`{{ fullname }}-{{ appName }}-sa`)

---

### ❌ SealedSecret not creating Secret

Check:
```bash
kubectl get sealedsecret
kubectl get secret
```

Fix:
- ensure sealed-secrets controller is installed in the target cluster
- ensure metadata namespace blocks match across both templates

---

### ❌ RBAC not applied

Check:
```bash
kubectl auth can-i get pods --as system:serviceaccount:<namespace>:<sa-name>
```

Fix:
- verify RoleBinding / ClusterRoleBinding subject references explicitly match the dynamic naming pattern.

---

### ❌ NetworkPolicy Traffic Drop (502/504 Bad Gateway via Ingress)

Symptoms:
- Ingress controller logs show upstream connection timeouts.
- External browser queries return HTTP 502/504 gateways.

Fix:
- Verify that your application's actual internal runtime port matches `.Values.service.targetPort` exactly.
- If `networkPolicy.allowOnlyFromIngress` is set to `true`, verify your ingress controller namespace label matches `.Values.networkPolicy.ingressNamespace`.
