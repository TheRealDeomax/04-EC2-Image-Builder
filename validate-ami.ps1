# AMI Validation Script (PowerShell)
# This script validates that the built AMI has the web service properly configured

param(
    [Parameter(Mandatory=$true)]
    [string]$InstanceIP
)

Write-Host "🔍 AMI Validation Script" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan

Write-Host "🎯 Testing instance at IP: $InstanceIP" -ForegroundColor Yellow

try {
    # Test main web page
    Write-Host "📄 Testing main web page..." -ForegroundColor Blue
    $mainPage = Invoke-WebRequest -Uri "http://$InstanceIP" -UseBasicParsing -TimeoutSec 10
    if ($mainPage.StatusCode -eq 200) {
        Write-Host "✅ Main web page is accessible" -ForegroundColor Green
    } else {
        throw "Main web page returned status code: $($mainPage.StatusCode)"
    }

    # Test health endpoint
    Write-Host "🏥 Testing health endpoint..." -ForegroundColor Blue
    $healthResponse = Invoke-WebRequest -Uri "http://$InstanceIP/health" -UseBasicParsing -TimeoutSec 10
    if ($healthResponse.Content.Trim() -eq "OK") {
        Write-Host "✅ Health endpoint returned: $($healthResponse.Content.Trim())" -ForegroundColor Green
    } else {
        throw "Health endpoint failed. Response: $($healthResponse.Content)"
    }

    # Test if page contains expected content
    Write-Host "📋 Checking page content..." -ForegroundColor Blue
    $pageContent = $mainPage.Content
    
    if ($pageContent -match "Welcome to Your Custom Amazon Linux AMI") {
        Write-Host "✅ Page contains expected welcome message" -ForegroundColor Green
    } else {
        throw "Page does not contain expected welcome message"
    }

    if ($pageContent -match "Apache HTTP Server") {
        Write-Host "✅ Page indicates Apache is running" -ForegroundColor Green
    } else {
        throw "Page does not indicate Apache is running"
    }

    # Performance test
    Write-Host "⚡ Running basic performance test..." -ForegroundColor Blue
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Invoke-WebRequest -Uri "http://$InstanceIP" -UseBasicParsing -TimeoutSec 10 | Out-Null
    $stopwatch.Stop()
    $responseTime = $stopwatch.ElapsedMilliseconds / 1000
    
    Write-Host "📊 Response time: ${responseTime}s" -ForegroundColor Magenta

    if ($responseTime -lt 2.0) {
        Write-Host "✅ Response time is acceptable" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Response time is slower than expected" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "🎉 Validation Complete!" -ForegroundColor Green
    Write-Host "=====================" -ForegroundColor Green
    Write-Host "✅ Web service is running correctly" -ForegroundColor Green
    Write-Host "✅ Health check is working" -ForegroundColor Green
    Write-Host "✅ Content is properly served" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Your custom AMI web service is ready to use!" -ForegroundColor Cyan
    Write-Host "   Access it at: http://$InstanceIP" -ForegroundColor Cyan

} catch {
    Write-Host ""
    Write-Host "❌ Validation Failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Verify the instance is running" -ForegroundColor White
    Write-Host "2. Check security group allows HTTP (port 80)" -ForegroundColor White
    Write-Host "3. Ensure the IP address is correct" -ForegroundColor White
    Write-Host "4. Wait a few minutes for services to fully start" -ForegroundColor White
    exit 1
}
