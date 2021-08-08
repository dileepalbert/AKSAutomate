# Secure APIs on Azure with AKS and Application Gateway



## Introduction

Ingress Security of Micro-services running within *K8s cluster* or as a *PasS* or *Serverless Function* is a basic requirement for Cloud Native applications. While *PaaS* and *Serverless* have options in-built being more managed and controlled services from Azure; but securing containerised applications, need additional steps and effort.

The containerised, micro-service APIs can be deployed on any type of K8s clusters on Azure - *Unmanaged* or *Managed*. Following example would use AKS as an easy integration option but can be replaced by any type of K8s cluster on Azure e.g. CAPZ K8s cluster.

The other container deployment option is to use Container Groups or ACI (Azure Container Instances). Current discussion would exclude that for now.

### What the Document does

- High level overview of how *SSL* flow works
- High level overview of the *Entities* involved - *Application Gateway, AKS, Ingress Controller*
- Components that play major roles within each *Entities*
- Deep Insights of Application Gateway components and how they work together
- Describe *SSL* options involved in end to end communication
- What *Configurations* are needed for each *SSL option* at the Ingress end of AKS cluster
- End to End example - *Access APIs securely through Application Gateway* to *Ingress of AKS cluster* and finally to the *APIs inside the cluster*

### What the Document does NOT

- Deep-dive into AKS and its associated components
- Deep-dive into SSL/TLS technology
- Introduction of *Firewall* into this architecture - *<u>this would be addressed in a separate article with deep insights of Azure Firewall and how that integrates with this architecture</u>*

### Pre-requisites, Assumptions

- Knowledge of SSL/TLS technology - *L200+*
- Knowledge on Containers, K8s, AKS - *L200+*
- Knowledge on Application Gateway  - *L200+*
- Knowledge on Azure tools & services viz. *Azure CLI, KeyVault, VNET* etc. - L200+



## Plan



## Action



## Summary



## References