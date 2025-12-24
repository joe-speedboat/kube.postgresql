#!/bin/bash

# This script automates the deployment of a PostgreSQL instance on a Kubernetes cluster.
# It handles namespace creation, secret management, and resource application.

# Get the current default namespace
current_namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
if [ -z "$current_namespace" ]; then
  current_namespace="default"
fi

# Prompt the user for the Kubernetes namespace to use, defaulting to the current namespace if not specified.
read -p "Enter Kubernetes namespace (default is '$current_namespace'): " namespace

# Use the provided namespace or default to the current one
if [ -z "$namespace" ]; then
  namespace="$current_namespace"
fi

# Check if the specified namespace exists; if not, create it.
if ! kubectl get namespace "$namespace" > /dev/null 2>&1; then
  echo "Namespace '$namespace' does not exist. Creating..."
  kubectl create namespace "$namespace"
fi

# Switch the current context to the specified namespace.
kubectl config set-context --current --namespace="$namespace"
# Function to generate a random password for PostgreSQL.
generate_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 16
}

# Prompt the user for PostgreSQL credentials, with the option to auto-generate passwords.
while [ -z "$root_pass" ]; do
  read -p "Enter PostgreSQL root password (press Enter to generate one): " root_pass
  if [ -z "$root_pass" ]; then
    root_pass=$(generate_password)
    echo "Generated root password: $root_pass"
  fi
done

while [ -z "$app_user" ]; do
  read -p "Enter PostgreSQL app user: " app_user
done

while [ -z "$app_db" ]; do
  read -p "Enter PostgreSQL app database: " app_db
done

while [ -z "$app_pass" ]; do
  read -p "Enter PostgreSQL app password (press Enter to generate one): " app_pass
  if [ -z "$app_pass" ]; then
    app_pass=$(generate_password)
    echo "Generated app password: $app_pass"
  fi
done

# Prompt the user for the Persistent Volume Claim (PVC) size, defaulting to '5Gi' if not specified.
read -p "Enter PVC size for PostgreSQL (default is '5Gi'): " pvc_size
if [ -z "$pvc_size" ]; then
  pvc_size="5Gi"
fi

# Encode the provided secrets in base64 format for Kubernetes secret creation.
root_pass_b64=$(echo -n "$root_pass" | base64 | tr -d '\n' | tr -d '\r')
app_user_b64=$(echo -n "$app_user" | base64 | tr -d '\n' | tr -d '\r')
app_db_b64=$(echo -n "$app_db" | base64 | tr -d '\n' | tr -d '\r')
app_pass_b64=$(echo -n "$app_pass" | base64 | tr -d '\n' | tr -d '\r')


# Export the encoded secrets as environment variables for use in template substitution.
export ROOT_PASS_B64="$root_pass_b64"
export APP_USER_B64="$app_user_b64"
export APP_DB_B64="$app_db_b64"
export APP_PASS_B64="$app_pass_b64"
export PVC_SIZE="$pvc_size"

# Apply the Kubernetes configurations using the substituted templates.
envsubst < k8s/secret.yaml.template | sed 's/mariadb/postgresql/g' | kubectl apply -f -
envsubst < k8s/persistent-volume-claim.yaml.template | kubectl apply -f -
sed 's/mariadb/postgresql/g' k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml

# Verify the deployment by listing the pods and services in the current namespace.
kubectl get pods
kubectl get svc
