# VLE-8: Blue-Green Deployment using DevOps Tools

Nityam Sharma (RA2311033010095)

| Path | Purpose |
|------|---------|
| `terraform/` | Provisions the Jenkins EC2 instance (Ubuntu 22.04) on AWS |
| `ansible/jenkins_setup.yml` | Configures Docker, Jenkins, kubectl and Minikube on it (over AWS SSM) |
| `app/` | nginx app; `VERSION`/`COLOR` build args produce v1 (blue) and v2 (green) |
| `k8s/deployment-blue.yaml`, `k8s/deployment-green.yaml` | Two identical environments |
| `k8s/service.yaml` | Live traffic; `selector.color` decides blue or green |
| `Jenkinsfile` | Build Green → Deploy Green → Test → **approve** → switch traffic → verify |

Switch / rollback:
```
kubectl patch service myapp-service -p '{"spec":{"selector":{"app":"myapp","color":"green"}}}'
kubectl patch service myapp-service -p '{"spec":{"selector":{"app":"myapp","color":"blue"}}}'
```
