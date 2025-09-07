param([string]`$Namespace = "retail")

Write-Host "🔍 Starting real-time scaling monitor..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

while (`$true) {
    Clear-Host
    Write-Host "=== KUBERNETES AUTOSCALING MONITOR ===" -ForegroundColor Cyan
    Write-Host "Time: `$(Get-Date)" -ForegroundColor White
    Write-Host "Namespace: `$Namespace" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📊 POD STATUS:" -ForegroundColor Yellow
    kubectl get pods -n `$Namespace -l app=retail-app -o wide
    Write-Host ""
    
    Write-Host "📈 HPA STATUS:" -ForegroundColor Yellow
    kubectl get hpa -n `$Namespace
    Write-Host ""
    
    Write-Host "⚡ RESOURCE USAGE:" -ForegroundColor Yellow
    try {
        kubectl top pods -n `$Namespace -l app=retail-app 2>`$null
    }
    catch {
        Write-Host "Metrics not available yet..." -ForegroundColor Gray
    }
    Write-Host ""
    
    Write-Host "🔄 RECENT EVENTS (last 5):" -ForegroundColor Yellow
    kubectl get events -n `$Namespace --sort-by='.lastTimestamp' | Select-Object -Last 5
    Write-Host ""
    Write-Host "Refreshing in 10 seconds... (Ctrl+C to stop)" -ForegroundColor Gray
    
    Start-Sleep -Seconds 10
}