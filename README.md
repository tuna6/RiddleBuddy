# RiddleBuddy 🎲

> AI-powered riddle app — a full DevOps showcase built on Kubernetes, AWS EKS, and OpenTelemetry.

[![Python](https://img.shields.io/badge/Python-3.11-blue)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green)](https://fastapi.tiangolo.com/)
[![Docker](https://img.shields.io/badge/Docker-ready-blue)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326CE5)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC)](https://www.terraform.io/)
[![CI](https://github.com/tuna6/RiddleBuddy/actions/workflows/ci.yml/badge.svg)](https://github.com/tuna6/RiddleBuddy/actions)

**Live Demo:** [riddlebuddy.nguyentu.online](https://riddlebuddy.nguyentu.online)

---

## What is this?

RiddleBuddy started as a simple joke app and evolved into a complete DevOps portfolio project. It generates AI-powered riddles via the DeepSeek API and demonstrates real-world practices across containerization, Kubernetes orchestration, infrastructure-as-code, CI/CD, and full observability.

---

## Architecture

> Full cloud architecture diagram: [nguyentu.online/#projects](https://nguyentu.online/#projects)

<!-- Add screenshot of your architecture diagram here -->
![Architecture](docs/images/architecture.png)

**Services:**
| Service | Tech | Description |
|---|---|---|
| `riddlebuddy-api` | FastAPI · Python | Core API, riddle generation via DeepSeek |
| `riddlebuddy-feedback` | Java Spring · :8080 | User feedback collection |
| `redis` | Redis · :6379 | Response caching |
| `otel-collector` | OpenTelemetry | Metrics, logs & traces aggregation |
| `grafana` | Grafana · EC2 | Dashboards & alerting |

---

## Tech Stack

| Layer | Tools |
|---|---|
| Cloud | AWS (EKS, VPC, ALB, EC2, AMP) |
| Containers | Kubernetes · Docker · Helm |
| IaC | Terraform |
| Observability | OpenTelemetry · Prometheus (AMP) · Grafana · Loki |
| CI/CD | GitHub Actions |
| Backend | FastAPI (Python) · Java Spring |
| Frontend | HTML · CSS · Vanilla JS |

---

## Deployment Options

This project supports three deployment modes. Each has its own dedicated guide:

| Mode | Description | Guide |
|---|---|---|
| 🖥️ **Local** | Full stack on your machine via k3s + Helm | [docs/deploy-local.md](docs/deploy-local.md) |
| ☁️ **Hybrid AWS** | App on k3s, monitoring on AWS (AMP) | [docs/deploy-hybrid.md](docs/deploy-hybrid.md) |
| 🚀 **Full AWS** | Everything on EKS + AWS managed services | [docs/deploy-aws.md](docs/deploy-aws.md) |

---

## Quick Start (Local)

**Prerequisites:** Docker, k3s, kubectl, helm

```bash
git clone https://github.com/tuna6/RiddleBuddy.git
cd RiddleBuddy

export DEEPSEEK_API_KEY=your_key_here
chmod +x deploy-local-full.sh
./deploy-local-full.sh
```

| Service | URL |
|---|---|
| App | http://localhost:30080/static |
| Grafana | http://localhost:3000 |

---

## What this project demonstrates

- **Kubernetes** — multi-service deployment with Helm, namespaces, ClusterIP/NodePort services
- **AWS EKS** — production-grade cluster with ALB ingress, NAT gateway, private subnets
- **Observability** — end-to-end with OpenTelemetry: metrics → AMP, logs → Loki, traces → Grafana
- **IaC** — full AWS infrastructure defined in Terraform
- **CI/CD** — GitHub Actions pipeline with Docker build, push, and Helm deploy
- **Security** — security groups, private subnet isolation, IRSA for pod-level AWS permissions

---

## Repository Structure

```
RiddleBuddy/
├── riddlebuddy-api/       # FastAPI service
├── riddlebuddy-feedback/  # Java Spring service
├── helm/                  # Helm charts
├── infra-cloud/           # Terraform (hybrid + full AWS)
├── .github/workflows/     # CI/CD pipelines
└── docs/                  # Deployment guides & diagrams
```

---

## License

MIT — contributions, feedback, or roasts welcome. 😄