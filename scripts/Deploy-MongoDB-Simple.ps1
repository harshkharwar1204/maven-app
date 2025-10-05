# Simple MongoDB Deployment Script
param([string]$Namespace = "retail")

Write-Host "=== MongoDB Deployment Starting ===" -ForegroundColor Cyan

# Check prerequisites
Write-Host "Checking kubectl..." -ForegroundColor Blue
try {
    kubectl version --client | Out-Null
    Write-Host "kubectl OK" -ForegroundColor Green
} catch {
    Write-Host "kubectl not found!" -ForegroundColor Red
    exit 1
}

# Create namespace
Write-Host "Creating namespace..." -ForegroundColor Blue
kubectl create namespace $Namespace 2>$null
if ($?) {
    Write-Host "Namespace created" -ForegroundColor Green
} else {
    Write-Host "Namespace already exists (OK)" -ForegroundColor Yellow
}

# Deploy MongoDB Secret
Write-Host "Deploying MongoDB Secret..." -ForegroundColor Blue
kubectl apply -f k8s-mongodb/mongodb-secret.yaml
Write-Host "Secret deployed" -ForegroundColor Green

# Deploy MongoDB ConfigMap
Write-Host "Deploying MongoDB ConfigMap..." -ForegroundColor Blue
kubectl apply -f k8s-mongodb/mongodb-configmap.yaml
Write-Host "ConfigMap deployed" -ForegroundColor Green

# Deploy MongoDB
Write-Host "Deploying MongoDB..." -ForegroundColor Blue
kubectl apply -f k8s-mongodb/mongodb-deployment.yaml
kubectl apply -f k8s-mongodb/mongodb-service.yaml
Write-Host "MongoDB deployed" -ForegroundColor Green

Write-Host "Waiting for MongoDB to be ready..." -ForegroundColor Blue
kubectl wait --for=condition=ready pod -l app=mongodb -n $Namespace --timeout=300s
Write-Host "MongoDB is ready!" -ForegroundColor Green

# Deploy Mongo Express
Write-Host "Deploying Mongo Express..." -ForegroundColor Blue
kubectl apply -f k8s-mongodb/mongo-express-deployment.yaml
kubectl apply -f k8s-mongodb/mongo-express-service.yaml
Write-Host "Mongo Express deployed" -ForegroundColor Green

Write-Host "Waiting for Mongo Express to be ready..." -ForegroundColor Blue
kubectl wait --for=condition=ready pod -l app=mongo-express -n $Namespace --timeout=300s
Write-Host "Mongo Express is ready!" -ForegroundColor Green

# Show status
Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Pods:" -ForegroundColor Cyan
kubectl get pods -n $Namespace
Write-Host ""
Write-Host "Services:" -ForegroundColor Cyan
kubectl get svc -n $Namespace
Write-Host ""

# Show access info
Write-Host "=== ACCESS INFORMATION ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "MongoDB Credentials:" -ForegroundColor Yellow
Write-Host "  Username: admin"
Write-Host "  Password: P@ssw0rd123"
Write-Host ""
Write-Host "Mongo Express Credentials:" -ForegroundColor Yellow
Write-Host "  Username: admin"
Write-Host "  Password: express123"
Write-Host ""
Write-Host "To access Mongo Express, run:" -ForegroundColor Green
Write-Host "  minikube service mongo-express-service -n retail" -ForegroundColor White
Write-Host ""
