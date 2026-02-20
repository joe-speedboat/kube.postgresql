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

while [ -z "$db_user" ]; do
  read -p "Enter PostgreSQL app user: " db_user
done

while [ -z "$db_name" ]; do
  read -p "Enter PostgreSQL database name: " db_name
done

while [ -z "$db_pass" ]; do
  read -p "Enter PostgreSQL db password (press Enter to generate one): " db_pass
  if [ -z "$db_pass" ]; then
    db_pass=$(generate_password)
    echo "Generated app password: $db_pass"
  fi
done

# Prompt the user for the Application version
read -p "Enter PostgreSQL version (default: 18): " pg_vers
if [ -z "$pg_vers" ]; then
  pg_vers="18"
fi

# Prompt the user for the Persistent Volume Claim (PVC) size, defaulting to '5Gi' if not specified.
read -p "Enter PVC size for PostgreSQL (default is '5Gi'): " pvc_size
if [ -z "$pvc_size" ]; then
  pvc_size="5Gi"
fi

# Encode the provided secrets in base64 format for Kubernetes secret creation.
db_user_b64=$(echo -n "$db_user" | base64 | tr -d '\n' | tr -d '\r')
db_name_b64=$(echo -n "$db_name" | base64 | tr -d '\n' | tr -d '\r')
db_pass_b64=$(echo -n "$db_pass" | base64 | tr -d '\n' | tr -d '\r')


# Export the encoded secrets as environment variables for use in template substitution.
export DB_USER_B64="$db_user_b64"
export DB_NAME_B64="$db_name_b64"
export DB_PASS_B64="$db_pass_b64"
export PVC_SIZE="$pvc_size"

# Apply the Kubernetes configurations using the substituted templates.
envsubst < k8s/secret.yaml.template | sed 's/mariadb/postgresql/g' | kubectl apply -f -
envsubst < k8s/persistent-volume-claim.yaml.template | kubectl apply -f -
sed "s/__PG_VERSION__/$pg_vers/g" k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml

# Verify the deployment by listing the pods and services in the current namespace.
kubectl get pods
kubectl get svc
