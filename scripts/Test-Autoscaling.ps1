# Kubernetes Autoscaling Test Script (PowerShell)
param(
    [string]$TestType = "all",
    [string]$Namespace = "retail",
    [string]$AppName = "retail-app"
)

function Write-Header { 
    param($Message)
    Write-Host "`n============================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "============================================`n" -ForegroundColor Blue
}

function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Blue }
function Write-Warning { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }

function Get-Status {
    try {
        $podCount = (kubectl get pods -n $Namespace -l app=$AppName --no-headers 2>$null | Measure-Object).Count
        $hpaInfo = kubectl get hpa retail-app-hpa -n $Namespace -o json 2>$null | ConvertFrom-Json
        $currentReplicas = if ($hpaInfo.status.currentReplicas) { $hpaInfo.status.currentReplicas } else { "N/A" }
        $cpuPercent = if ($hpaInfo.status.currentCPUUtilizationPercentage) { $hpaInfo.status.currentCPUUtilizationPercentage } else { "N/A" }
        
        return "Pods: $podCount | Replicas: $currentReplicas | CPU: $cpuPercent%"
    }
    catch {
        return "Status unavailable"
    }
}

function Test-Baseline {
    Write-Header "BASELINE FUNCTIONALITY TEST"
    
    Write-Info "Testing application health..."
    $testName = "test-health-" + (Get-Random)
    try {
        kubectl run $testName --image=curlimages/curl:latest -n $Namespace --rm -it --restart=Never -- curl -f http://retail-app-internal.retail.svc.cluster.local:8081/actuator/health
        Write-Success "Application is healthy"
    }
    catch {
        Write-Host "Health check failed" -ForegroundColor Red
        return
    }
    
    Write-Info "Current status:"
    Write-Host (Get-Status)
}

function Test-LightLoad {
    Write-Header "LIGHT LOAD TEST (Normal Social Media Traffic)"
    
    $jobName = "light-load-" + (Get-Date -Format "yyyyMMddHHmmss")
    $yamlContent = @"
apiVersion: batch/v1
kind: Job
metadata:
  name: $jobName
  namespace: $Namespace
spec:
  parallelism: 3
  completions: 3
  template:
    spec:
      containers:
      - name: load-generator
        image: curlimages/curl:latest
        command:
        - /bin/sh
        - -c
        - |
          echo "Light load started - `$HOSTNAME"
          end_time=`$((`$(date +%s) + 90))
          
          while [ `$(date +%s) -lt `$end_time ]; do
            curl -s http://retail-app-internal:8081/api/products > /dev/null || echo "Request failed"
            
            if [ `$((`$RANDOM % 10)) -lt 3 ]; then
              curl -s -X POST http://retail-app-internal:8081/api/products \
                -H 'Content-Type: application/json' \
                -d "{\"name\":\"Post`$(date +%s)\",\"description\":\"User post\",\"price\":`$((`$RANDOM % 100 + 1)).99}" > /dev/null || echo "POST failed"
            fi
            
            sleep 2
          done
          echo "Light load completed"
      restartPolicy: Never
"@
    
    $yamlContent | kubectl apply -f -
    
    Write-Info "Monitoring light load for 2 minutes..."
    Start-Sleep -Seconds 120
    
    kubectl delete job $jobName -n $Namespace --ignore-not-found=true
    Write-Success "Light load test completed"
}

function Test-HeavyLoad {
    Write-Header "HEAVY LOAD TEST (Viral Social Media Traffic)"
    
    Write-Warning "Simulating viral content traffic spike..."
    
    $jobName = "heavy-load-" + (Get-Date -Format "yyyyMMddHHmmss")
    $yamlContent = @"
apiVersion: batch/v1
kind: Job
metadata:
  name: $jobName
  namespace: $Namespace
spec:
  parallelism: 8
  completions: 8
  template:
    spec:
      containers:
      - name: load-generator
        image: curlimages/curl:latest
        command:
        - /bin/sh
        - -c
        - |
          echo "Heavy load started - `$HOSTNAME"
          end_time=`$((`$(date +%s) + 180))
          
          while [ `$(date +%s) -lt `$end_time ]; do
            for i in `$(seq 1 5); do
              case `$((`$i % 10)) in
                0|1|2|3|4|5) curl -s http://retail-app-internal:8081/api/products > /dev/null & ;;
                6|7) curl -s -X POST http://retail-app-internal:8081/api/products \
                       -H 'Content-Type: application/json' \
                       -d "{\"name\":\"Viral`$(date +%s)\",\"description\":\"Trending\",\"price\":99.99}" > /dev/null & ;;
                8|9) curl -s http://retail-app-internal:8081/api/products/`$((`$RANDOM % 10 + 1)) > /dev/null & ;;
              esac
            done
            sleep 0.5
          done
          wait
          echo "Heavy load completed"
      restartPolicy: Never
"@
    
    $yamlContent | kubectl apply -f -
    
    Write-Info "Monitoring heavy load for 4 minutes..."
    for ($i = 0; $i -lt 16; $i++) {
        Write-Host "Status: $(Get-Status)"
        Start-Sleep -Seconds 15
    }
    
    kubectl delete job $jobName -n $Namespace --ignore-not-found=true
    Write-Success "Heavy load test completed"
}

# Main execution
Write-Header "KUBERNETES AUTOSCALING TEST SUITE"
Write-Info "Testing your enhanced CRUD application"

switch ($TestType.ToLower()) {
    "baseline" { Test-Baseline }
    "light" { Test-LightLoad }
    "heavy" { Test-HeavyLoad }
    "status" {
        Write-Info "Current Status:"
        Write-Host (Get-Status)
        kubectl get pods -n $Namespace -l app=$AppName
        kubectl get hpa -n $Namespace
    }
    default {
        Test-Baseline
        Test-LightLoad
        Test-HeavyLoad
    }
}

Write-Success "Testing completed!"
