# api7-ingress-controller

![Version: 0.1.7](https://img.shields.io/badge/Version-0.1.7-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.0.3](https://img.shields.io/badge/AppVersion-2.0.3-informational?style=flat-square)

Ingress Controller for API7

## Source Code

* <https://github.com/api7/api7-helm-chart>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autoscaling.enabled | bool | `false` |  |
| autoscaling.minReplicas | int | `1` |  |
| config.controllerName | string | `"apisix.apache.org/apisix-ingress-controller"` |  |
| config.enableHTTP2 | bool | `false` |  |
| config.execADCTimeout | string | `"15s"` |  |
| config.leaderElection.disable | bool | `false` |  |
| config.leaderElection.id | string | `"apisix-ingress-controller-leader"` |  |
| config.leaderElection.leaseDuration | string | `"15s"` |  |
| config.leaderElection.renewDeadline | string | `"10s"` |  |
| config.leaderElection.retryPeriod | string | `"2s"` |  |
| config.logLevel | string | `"info"` |  |
| config.metricsAddr | string | `":8080"` |  |
| config.probeAddr | string | `":8081"` |  |
| config.provider.initSyncDelay | string | `"20m"` |  |
| config.provider.syncPeriod | string | `"0s"` |  |
| config.provider.type | string | `"api7ee"` |  |
| config.secureMetrics | bool | `false` |  |
| deployment.affinity | object | `{}` |  |
| deployment.annotations | object | `{}` |  |
| deployment.image.pullPolicy | string | `"IfNotPresent"` |  |
| deployment.image.repository | string | `"api7/api7-ingress-controller"` |  |
| deployment.image.tag | string | `"2.0.3"` |  |
| deployment.nodeSelector | object | `{}` |  |
| deployment.podAnnotations | object | `{}` |  |
| deployment.podSecurityContext | object | `{}` |  |
| deployment.replicas | int | `1` |  |
| deployment.tolerations | list | `[]` |  |
| deployment.topologySpreadConstraints | list | `[]` |  |
| fullnameOverride | string | `""` |  |
| labelsOverride | object | `{}` |  |
| nameOverride | string | `""` |  |
| podDisruptionBudget | object | `{"enabled":false,"maxUnavailable":1,"minAvailable":"90%"}` | See https://kubernetes.io/docs/tasks/run-application/configure-pdb/ for more details |
| podDisruptionBudget.enabled | bool | `false` | Enable or disable podDisruptionBudget |
| podDisruptionBudget.maxUnavailable | int | `1` | Set the maxUnavailable of podDisruptionBudget |
| podDisruptionBudget.minAvailable | string | `"90%"` | Set the `minAvailable` of podDisruptionBudget. You can specify only one of `maxUnavailable` and `minAvailable` in a single PodDisruptionBudget. See [Specifying a Disruption Budget for your Application](https://kubernetes.io/docs/tasks/run-application/configure-pdb/#specifying-a-poddisruptionbudget) for more details |

