# Terraform Module for EKS Cluster

This Terraform module sets up a Noname Sensor and Remote Operator on an AWS Elastic Kubernetes Service using a Helm chart.

## Requirements

- Terraform version >= 0.14
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured
- [Helm CLI](https://helm.sh/docs/intro/install/) installed

## Providers

This module requires the following providers:

- Kubernetes (version ~> 2.25)
- Helm (version ~> 2.13)

## Inputs

| Name                          | Description                                      | Type   | Default              | Required |
| ----------------------------- | ------------------------------------------------ | :----: | :------------------: | :------: |
| `cluster_name`                | The name of the EKS cluster                      | string | n/a                  | yes      |
| `noname_kubernetes_namespace` | Name of the namespace to deploy noname sensor in | string | noname-security      | no       |
| `helm_folder_path`            | Path to the folder containing Chart.yml file     | string | current folder (`.`) | no       |

## Usage

### Step-by-Step Guide
1. **Create an AWS provider and define the data sources for AWS EKS Cluster and its authentication**:
    ```hcl
    provider "aws" {
      region = "us-east-1"
    }

    locals {
      cluster_name = "name-of-eks-cluster"
    }

    data "aws_eks_cluster" "eks_cluster" {
      name = local.cluster_name
    }

    data "aws_eks_cluster_auth" "eks_cluster_auth" {
      name = local.cluster_name
    }
    ```
2. **Create a Helm and Kubernetes providers**:
    ```hcl
    provider "kubernetes" {
      alias                  = "noname-remote-operator"
      host                   = data.aws_eks_cluster.eks_cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
      token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
    }

    provider "helm" {
      alias = "noname-remote-operator"
      kubernetes {
        host                   = data.aws_eks_cluster.eks_cluster.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
        token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
      }
    }
    ```

3. **Call the module**:
    ```hcl
    module "noname_remote_operator" {
      source       = "./terraform-modules/eks"
      cluster_name = local.cluster_name
      providers = {
        kubernetes = kubernetes.noname-remote-operator
        helm       = helm.noname-remote-operator
      }
    }
    ```