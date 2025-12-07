# Usage
To deploy this helm chart the following example application is setup. These files are setup under a seperate repostiory.


**whoami/Chart.yaml**
```yaml
apiVersion: v2
name: whoami
version: 1.0.20

dependencies:
  - name: helm-base
    version: ">=1.0.0"
    repository: "https://john-ghatas.github.io/helmhub"
```

**whoami/values.yaml**
```yaml
image:
  repository: traefik/whoami  # container image repository
  tag: latest                 # container image tag
  pullPolicy: IfNotPresent    # image pull policy

service:
  type: LoadBalancer          # service type
  port: 8080                  # service port
  annotations:
    metallb.universe.tf/loadBalancerIPs: "192.168.50.21"  # static IP for MetalLB

env:
  INSTANCE_NAME: "tenant-a-whoami"  # environment variable for tenant identification

configmaps:
  LOG_LEVEL: "debug"           # example configmap entries
  FEATURE_FLAG: "true"

sealed:
  PASSWORD: "AgEncryptedPassword=="  # sealed secret for password
  API_KEY: "AgEncryptedApiKey=="     # sealed secret for API key

persistence:
  enabled: true                # enable persistent storage
  size: 2Gi                    # PVC size
  accessModes:
    - ReadWriteMany            # PVC access mode
  pvName: "whoami-tenant-a-pv" # PV name
  subPath: "tenant-a/whoami"   # optional subpath in PV
  nfs:
    server: "<nfs-ip>"         # NFS server IP
    path: "/srv/exports"       # NFS export path

replicaCount: 1                # default number of replicas (pinned 1:1)

autoscaling:
  enabled: false                # enable HPA if true
  minReplicas: 1                # min replicas if autoscaling enabled
  maxReplicas: 1                # max replicas if autoscaling enabled
  targetCPUUtilizationPercentage: 70  # CPU utilization target for HPA

podSecurityContext:
  enabled: true                 # enable pod-level security context
  runAsNonRoot: true            # enforce non-root user
  runAsUser: 1000               # UID for pod
  fsGroup: 1000                 # group ownership for mounted volumes

containerSecurity:
  enabled: false                # enable container-level security context
  readOnlyRootFilesystem: true  # enforce read-only root filesystem
  allowPrivilegeEscalation: false # disallow privilege escalation
  capabilities:
    drop:
      - ALL                    # drop all Linux capabilities

seccompProfile:
  enabled: true                 # enable seccomp profile
  type: RuntimeDefault          # modern seccomp type
```

To deploy and upgrade the helm chart use the following commands
```bash
helm dependency update ./whoami
# helm upgrade --install <helm-install> ./<directory-to-chart> -n <kubernetes-namespace>
helm upgrade --install whoami ./whoami -n whoami
```