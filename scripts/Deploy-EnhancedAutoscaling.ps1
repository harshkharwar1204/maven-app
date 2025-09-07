# Enhanced Kubernetes Autoscaling Deployment Script (PowerShell)
param(
    [string]$Namespace = "retail",
    [string]$AppName = "retail-app",
    [string]$ImageName = "kharwarharsh1204/crudapp:latest"
)

function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Blue }
function Write-Warning { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error "kubectl not found. Please install kubectl."
        exit 1
    }
    
    try {
        kubectl cluster-info | Out-Null
        Write-Success "Prerequisites satisfied"
    }
    catch {
        Write-Error "Cannot connect to Kubernetes cluster"
        Write-Info "If using minikube, run: minikube start"
        exit 1
    }
}

function Install-MetricsServer {
    Write-Info "Checking metrics server..."
    
    try {
        kubectl get deployment metrics-server -n kube-system | Out-Null
        Write-Success "Metrics server already installed"
    }
    catch {
        Write-Warning "Installing metrics server..."
        if ((kubectl config current-context) -match "minikube") {
            minikube addons enable metrics-server
        }
        else {
            kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
        }
        Write-Success "Metrics server installed"
        Write-Warning "Waiting 30 seconds for metrics server to be ready..."
        Start-Sleep -Seconds 30
    }
}

function New-KubernetesNamespace {
    Write-Info "Creating namespace '$Namespace'..."
    
    try {
        kubectl get namespace $Namespace | Out-Null
        Write-Warning "Namespace '$Namespace' already exists"
    }
    catch {
        kubectl create namespace $Namespace
        Write-Success "Created namespace '$Namespace'"
    }
}

function Deploy-Application {
    Write-Info "Deploying enhanced application..."
    
    kubectl apply -f k8s-enhanced\deployment-production.yaml
    kubectl apply -f k8s-enhanced\service-enhanced.yaml
    kubectl apply -f k8s-enhanced\hpa-advanced.yaml
    kubectl apply -f k8s-enhanced\monitoring.yaml
    
    Write-Success "Application deployed"
    
    Write-Info "Waiting for deployment to be ready..."
    kubectl rollout status deployment/$AppName -n $Namespace --timeout=300s
    Write-Success "Deployment is ready"
}

function Test-Deployment {
    Write-Info "Verifying deployment..."
    
    Write-Host "Pods:" -ForegroundColor Cyan
    kubectl get pods -n $Namespace -l app=$AppName
    
    Write-Host "
Services:" -ForegroundColor Cyan
    kubectl get svc -n $Namespace
    
    Write-Host "
HPA:" -ForegroundColor Cyan
    kubectl get hpa -n $Namespace
    
    Write-Success "Deployment verification completed"
}

function Show-AccessInfo {
    Write-Info "Access Information:"
    Write-Host "Port forward: kubectl port-forward service/retail-app-svc 8080:80 -n retail" -ForegroundColor Yellow
    
    if ((kubectl config current-context) -match "minikube") {
        Write-Host "Minikube: minikube service retail-app-svc -n retail" -ForegroundColor Yellow
    }
    
    Write-Host "Internal URL: http://retail-app-internal.retail.svc.cluster.local:8081" -ForegroundColor Yellow
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Enhanced Kubernetes Autoscaling Deploy" -ForegroundColor Cyan
Write-Host "Building on your existing CRUD app" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Test-Prerequisites
Install-MetricsServer
New-KubernetesNamespace
Deploy-Application
Test-Deployment
Show-AccessInfo

Write-Success "Enhanced deployment completed!"
Write-Info "Your application now has enterprise-grade autoscaling capabilities"

Write-Host "
Next steps:" -ForegroundColor Green
Write-Host "1. Test scaling: .\scripts\Test-Autoscaling.ps1"
Write-Host "2. Monitor: kubectl get pods -n retail (in another terminal)"
Write-Host "3. Load test: .\scripts\Start-LoadTest.ps1"
