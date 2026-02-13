# RiddleBuddy 🎉

Simple, kid-friendly joke & riddle web app built with **FastAPI**.  
Portfolio project to demonstrate DevOps practices: Docker, CI/CD, Kubernetes, IaC, monitoring.

[![Python](https://img.shields.io/badge/Python-3.11-blue)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green)](https://fastapi.tiangolo.com/)
[![Docker](https://img.shields.io/badge/Docker-Container-blue)](https://www.docker.com/)

Live Demo: (coming soon - deploying to Railway)  
GitHub Actions CI: (badge will appear after pipeline setup)

## 📸 Screenshot

![App Screenshot](docs/images/screenshot-app.png)

## Architecture

- riddlebuddy-api (FastAPI)
- riddlebuddy-feedback (Java Spring)
- Redis
- Monitoring stack:
 -- Prometheus (metrics)
 -- Loki + Promtail (logs)
 -- Grafana (dashboards)


## Tech stack 
- Backend & API: FastAPI (Python)  
- Frontend: Basic HTML + CSS + Vanilla JS  
- Containerization: Docker  
- GitHub Actions, Kubernetes (k3s), Terraform (later), Prometheus + Grafana  + Loki

## Prerequisites
- Linux
- Docker
- k3s
- kubectl
- helm
- DEEPSEEK_API_KEY env var

## Quick Start (Local)
```bash
# Clone repo
export DEEPSEEK_API_KEY=xxxx
git clone https://github.com/yourusername/riddlebuddy.git
chmod +x deploy-local-full.sh
./deploy-local.sh


# Access app: http://localhost:30080/static
# Access grafana: http://localhost:3000
```

## Quick Start (Local + aws monitoring)
```bash
# Clone repo
export DEEPSEEK_API_KEY=xxxx
git clone https://github.com/yourusername/riddlebuddy.git
chmod +x deploy-local.sh
./deploy-local.sh



## Why this project?
Started as a fun joke app → evolved into a full DevOps showcase.  
Goal: Demonstrate containerization, automation, orchestration, and cloud thinking.  
Contributions, feedback, or roast welcome! 😄

