# Usage
To deploy this helm chart the following example application is setup. These files are setup under a seperate repostiory.


**whoami/Chart.yaml**
```yaml
apiVersion: v2
name: whoami
version: 1.0.0

dependencies:
  - name: helm-base
    version: ">=1.0.0"
    repository: "https://john-ghatas.github.io/helmhub"
```

**whoami/values.yaml**
```yaml
image:
  repository: traefik/whoami
  tag: latest
  pullPolicy: IfNotPresent

service:
  port: 8080
  annotations:
    metallb.universe.tf/loadBalancerIPs: "192.168.50.21"

env:
  INSTANCE_NAME: "tenant-a-whoami"

configmaps:
  LOG_LEVEL: "debug"
  FEATURE_FLAG: "true"

sealed:
  PASSWORD: "AgEncryptedPassword=="
  API_KEY: "AgEncryptedApiKey=="

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

persistence:
  enabled: true
  size: 2Gi
  accessModes:
    - ReadWriteMany
  pvName: "whoami-tenant-a-pv"
  subPath: "tenant-a/whoami"
  nfs:
    server: "<nfs-ip>"
    path: "/srv/exports"
```

To deploy and upgrade the helm chart use the following commands
```bash
helm dependency update ./whoami
# helm upgrade --install <helm-install> ./<directory-to-chart> -n <kubernetes-namespace>
helm upgrade --install whoami ./whoami -n whoami
```