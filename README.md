# Infra-Lab Terraform Project (IN PROGRESS)

This project sets up infrastructure for a Talos Kubernetes cluster using Terraform. It includes configurations for Oracle Cloud Infrastructure (OCI), Tailscale, and Cloudflare DNS records.

## Prerequisites

Before you begin, ensure you have the following installed on your local machine:

- [Terraform](https://www.terraform.io/downloads.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [jq](https://stedolan.github.io/jq/download/)
- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)

## Project Structure

The project is organized as follows:
infra-lab/ ├── terraform/ │ ├── modules/ │ │ └── infra/ │ │ └── talos-node/ │ │ ├── main.tf │ │ ├── variables.tf │ ├── stacks/ │ │ └── cluster-deployment/ │ │ └── config.tm.hcl ├── README.md

- **modules/infra/talos-node/**: Contains the Terraform module for setting up Talos nodes.
- **stacks/cluster-deployment/**: Contains the configuration for deploying the Talos cluster.

## Usage

### 1. Clone the Repository

```sh
git clone https://github.com/your-username/infra-lab.git
cd infra-lab/terraform/stacks/cluster-deployment
```
