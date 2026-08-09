# Microservice Helm Chart

Production-ready microservice chart with:
- sidecar slot support (for OTel collector or other sidecars)
- messaging value contract (`messaging.*`)
- service mesh value contract (`serviceMesh.*`)

## Files

- `Chart.yaml`
- `values.yaml`
- `values.dev.yaml`
- `values.prod.yaml`
- `templates/`
	- `_helpers.tpl`
	- `deployment.yaml`
	- `service.yaml`
	- `ingress.yaml`
	- `hpa.yaml`
	- `pdb.yaml`
	- `serviceaccount.yaml`
	- `networkpolicy.yaml`

## Usage

```bash
helm install my-service cd/helm/microservice -f cd/helm/microservice/values.dev.yaml
helm upgrade my-service cd/helm/microservice -f cd/helm/microservice/values.prod.yaml
```
