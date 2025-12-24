# Kubernetes Single Pod Deployment for PostgreSQL

This project provides a set of Kubernetes configurations and a deployment script to set up a single pod PostgreSQL instance. It includes resources for deployment, secrets, persistent storage, and service exposure.

## Features

- **Automated Deployment**: Easily deploy a PostgreSQL instance with a single script.
- **Secure Secrets Management**: Automatically generate and manage database credentials.
- **Persistent Storage**: Configure persistent storage for data durability.
- **Namespace Management**: Create and manage Kubernetes namespaces as needed.

## Prerequisites

- A running Kubernetes cluster.
- `kubectl` command-line tool configured to interact with your cluster.
- Sufficient permissions to create namespaces, secrets, and other resources.

## Deployment Instructions

1. **Run the Deployment Script**: Execute the `deploy_postgresql.sh` script to start the deployment process.
   ```bash
   ./deploy_postgresql.sh
   ```

2. **Follow the Prompts**: The script will guide you through setting up the necessary credentials and configurations. You can choose to generate random passwords or provide your own.

3. **Verify Deployment**: After the script completes, verify the deployment by checking the status of the pods and services.
   ```bash
   kubectl get pods
   kubectl get svc
   ```

4. **Access PostgreSQL**: Use the service to connect to PostgreSQL. The service exposes PostgreSQL on port 5432 within the cluster.

## Customization

- **Secrets**: Modify the `k8s/secret.yaml.template` to customize the database credentials.
- **Storage**: Adjust the `k8s/persistent-volume-claim.yaml.template` to change the storage size.
- **Deployment**: Update `k8s/deployment.yaml` to modify the deployment specifications.

## Troubleshooting

- Ensure your Kubernetes context is set correctly.
- Check for any error messages during the script execution and resolve them as needed.
- Verify that the namespace and resources are created successfully.

1. **Create Secrets**: Encode your secrets in base64 and replace the placeholders in `k8s/secret.yaml`.
   ```bash
   echo -n 'your-root-password' | base64
   echo -n 'your-app-user' | base64
   echo -n 'your-app-db' | base64
   echo -n 'your-app-pass' | base64
   ```

2. **Apply Kubernetes Configurations**:
   ```bash
   kubectl apply -f k8s/secret.yaml
   kubectl apply -f k8s/persistent-volume-claim.yaml
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/service.yaml
   ```

3. **Verify Deployment**:
   ```bash
   kubectl get pods
   kubectl get svc
   ```

4. **Access PostgreSQL**: Use the service to connect to PostgreSQL.
