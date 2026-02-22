# 🦾 OpenClaw — AI Agent System on Kubernetes

> מערכת AI אגנטית מלאה שרצה על Kubernetes ב-AWS עם פריסה אוטומטית מקצה לקצה

[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-blue?logo=github)](https://github.com/doronsun/openclaw)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.29-326CE5?logo=kubernetes)](https://kubernetes.io)
[![Docker](https://img.shields.io/badge/Docker-Multi--Platform-2496ED?logo=docker)](https://hub.docker.com/u/doronsun)
[![AWS](https://img.shields.io/badge/AWS-EC2%20%2B%20Secrets%20Manager-FF9900?logo=amazonaws)](https://aws.amazon.com)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)](https://terraform.io)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER                                     │
│                    📱 Telegram App                               │
└─────────────────────────┬───────────────────────────────────────┘
                          │ Message
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS EC2 MASTER NODE                           │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  🧠 Brain Pod                             │   │
│  │   1. Receive message from Telegram                       │   │
│  │   2. Ask Groq AI → "Which agent?"                        │   │
│  │   3. Save status to Redis                                │   │
│  │   4. Create Kubernetes Job                               │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  🗃️ Redis Pod                             │   │
│  │   • Stores conversation history (10 messages)            │   │
│  │   • Stores job status (running/done)                     │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────┬───────────────────────────────────────┘
                          │ Create Job
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS EC2 WORKER NODE                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  🔬 Researcher│  │  💻 Coder    │  │  📝 Summarizer       │  │
│  │     Agent    │  │    Agent     │  │       Agent          │  │
│  │  Job Pod     │  │  Job Pod     │  │     Job Pod          │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
│         │                 │                       │              │
│         └─────────────────┴───────────────────────┘             │
│                           │ Ask Groq AI                         │
│                           ▼                                      │
│                    📤 Send answer to Telegram                    │
│                    🗑️ Job auto-deleted                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Message Flow

```
User sends message
        │
        ▼
    Brain receives
        │
        ▼
    Groq decides agent type
    ┌───────────────────┐
    │  researcher ?     │
    │  coder ?          │
    │  summarizer ?     │
    └───────────────────┘
        │
        ▼
    Brain sends "Working on it... ⚙️"
        │
        ▼
    Kubernetes Job created on Worker
        │
        ▼
    Agent runs with Groq
        │
        ▼
    Answer sent back to Telegram
        │
        ▼
    Job auto-deleted (TTL: 60s)
```

---

## 🏛️ Infrastructure Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud (eu-central-1)                  │
│                                                                   │
│  ┌─────────────────┐          ┌─────────────────┐               │
│  │   EC2 Master    │          │   EC2 Worker    │               │
│  │   t3.small      │◄────────►│   t2.micro      │               │
│  │                 │  K8s     │                 │               │
│  │  Brain Pod      │  Network │  Agent Jobs     │               │
│  │  Redis Pod      │          │                 │               │
│  │  Portainer Pod  │          │                 │               │
│  └────────┬────────┘          └─────────────────┘               │
│           │                                                       │
│           │                                                       │
│  ┌────────▼────────────────────────────────────────────────┐    │
│  │              AWS Secrets Manager                         │    │
│  │  • TELEGRAM_TOKEN                                        │    │
│  │  • GROQ_API_KEY                                          │    │
│  │  • DOCKERHUB_USERNAME                                    │    │
│  │  • DOCKERHUB_TOKEN                                       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              IAM Role: openclaw-ec2-role                 │    │
│  │  • SecretsManagerReadWrite                               │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🚀 CI/CD Pipeline

```
Developer pushes code
        │
        ▼
    GitHub Actions triggered
        │
        ├─► Build Brain Image (multi-platform)
        │       linux/amd64 + linux/arm64
        │       Push to DockerHub
        │
        ├─► Build Agent Image (multi-platform)
        │       linux/amd64 + linux/arm64
        │       Push to DockerHub
        │
        └─► Deploy to Kubernetes
                kubectl rollout restart
                Wait for rollout complete
```

---

## 🛡️ Security Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Security Layers                              │
│                                                                   │
│  Layer 1: AWS Security Group                                     │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Port 22   → SSH (admin only)                            │   │
│  │  Port 6443 → Kubernetes API                              │   │
│  │  Port 30000-32767 → NodePort Services                    │   │
│  │  Internal VPC → All traffic allowed                      │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  Layer 2: Kubernetes RBAC                                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  brain-sa → can only: create/delete/get/list Jobs        │   │
│  │  brain-sa → can only: get/list Pods and logs             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  Layer 3: NetworkPolicy                                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Brain → Redis: allowed                                  │   │
│  │  Brain → HTTPS (443): allowed (Telegram, Groq)           │   │
│  │  Brain → everything else: BLOCKED                        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  Layer 4: Secrets Management                                     │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  AWS Secrets Manager → encrypted at rest                 │   │
│  │  Kubernetes Secrets → injected as env vars               │   │
│  │  No secrets in code or git                               │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
openclaw/
├── 📂 terraform/
│   ├── main.tf          # AWS infrastructure (EC2, SG, IAM)
│   ├── variables.tf     # Input variables
│   ├── outputs.tf       # Output values (IPs, SSH commands)
│   └── terraform.tfvars # Variable values
│
├── 📂 brain/
│   ├── main.py          # Telegram bot + Router Agent + K8s Job creator
│   ├── requirements.txt # Python dependencies
│   └── Dockerfile       # Multi-platform Docker image
│
├── 📂 agent/
│   ├── agent.py         # AI Agent (researcher/coder/summarizer)
│   ├── requirements.txt # Python dependencies
│   └── Dockerfile       # Multi-platform Docker image
│
├── 📂 k8s/
│   ├── brain.yaml       # Brain Deployment + Probes + NodeSelector
│   ├── redis.yaml       # Redis Deployment + Service
│   ├── rbac.yaml        # ServiceAccount + ClusterRole + Binding
│   ├── quota.yaml       # ResourceQuota (max 10 jobs)
│   └── network-policy.yaml # Zero Trust NetworkPolicy
│
└── 📂 .github/
    └── workflows/
        └── deploy.yml   # CI/CD Pipeline
```

---

## ⚡ Quick Start

### Prerequisites
- AWS CLI configured
- Terraform installed
- kubectl installed

### Deploy

```bash
# Clone the repo
git clone https://github.com/doronsun/openclaw.git
cd openclaw

# Create secrets in AWS
aws secretsmanager create-secret \
  --name "openclaw/secrets" \
  --region eu-central-1 \
  --secret-string '{"TELEGRAM_TOKEN":"...","GROQ_API_KEY":"...","DOCKERHUB_USERNAME":"...","DOCKERHUB_TOKEN":"..."}'

# Deploy infrastructure
cd terraform
terraform init
terraform apply

# Connect worker node (get join command from master)
ssh -i your-key.pem ubuntu@<master-ip>
cat ~/join-command.sh

# Run join command on worker
ssh -i your-key.pem ubuntu@<worker-ip>
sudo kubeadm join ...

# Done! Check pods
kubectl get pods
```

---

## 🔧 Technologies Used

| Category | Technology | Purpose |
|----------|-----------|---------|
| **Cloud** | AWS EC2 | Virtual machines |
| **Cloud** | AWS Secrets Manager | Secure secrets storage |
| **IaC** | Terraform | Infrastructure as Code |
| **Orchestration** | Kubernetes v1.29 | Container orchestration |
| **Networking** | Flannel CNI | Pod networking |
| **Containers** | Docker | Container runtime |
| **Registry** | DockerHub | Image storage |
| **CI/CD** | GitHub Actions | Automated deployment |
| **AI** | Groq (LLaMA 3.3 70B) | AI processing |
| **Messaging** | Telegram Bot API | User interface |
| **Cache** | Redis | Conversation memory |
| **Monitoring** | Portainer | K8s dashboard |
| **Security** | RBAC + NetworkPolicy | Zero Trust security |

---

## 📊 System Capabilities

- ✅ **Auto-routing** — AI decides which agent handles each request
- ✅ **Memory** — Redis stores last 10 messages per user
- ✅ **Auto-healing** — Liveness/Readiness Probes restart failed pods
- ✅ **Auto-scaling ready** — ResourceQuota protects from overload (max 10 jobs)
- ✅ **Zero Trust Security** — NetworkPolicy limits all traffic
- ✅ **Full automation** — One `terraform apply` deploys everything
- ✅ **CI/CD** — Every git push auto-builds and deploys
- ✅ **Visual monitoring** — Portainer dashboard with real-time logs

---

## 👨‍💻 Author

**Doron Sun** — Built with ❤️ and a lot of `terraform destroy`

---

> *"The best infrastructure is the one you never have to think about"*
