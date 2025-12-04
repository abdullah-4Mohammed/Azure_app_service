Flask App Deployment on Azure App Service

This project deploys a Flask web application to Azure App Service using Terraform. The application container image is stored in Azure Container Registry (ACR) and pulled by Azure App Service, which provides fully managed container deployment and scaling.

Project Overview

Infrastructure as Code (IaC): Terraform manages the deployment and configuration of Azure resources.
Container Registry: Azure Container Registry (ACR) hosts the Docker image.
Compute Service: Azure App Service manages the application deployment and auto-scaling.
Identity Management: Managed Identity for App Service to securely pull the container image from ACR.

Azure Resources

The following Azure resources are created:

Resource Group to organize all related resources.
Managed Identity for App Service to access ACR.
Azure Container Registry (ACR) to store the container image.
App Service Plan to define the hosting environment.
App Service to deploy the Flask application and handle auto-scaling.
