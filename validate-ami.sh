#!/bin/bash

# AMI Validation Script
# This script validates that the built AMI has the web service properly configured

set -e

echo "🔍 AMI Validation Script"
echo "======================="

# Check if instance ID is provided
if [ -z "$1" ]; then
    echo "❌ Usage: $0 <instance-ip-address>"
    echo "   Example: $0 52.23.45.67"
    exit 1
fi

INSTANCE_IP=$1
echo "🎯 Testing instance at IP: $INSTANCE_IP"

# Test main web page
echo "📄 Testing main web page..."
if curl -f -s "http://$INSTANCE_IP" > /dev/null; then
    echo "✅ Main web page is accessible"
else
    echo "❌ Main web page is not accessible"
    exit 1
fi

# Test health endpoint
echo "🏥 Testing health endpoint..."
HEALTH_RESPONSE=$(curl -f -s "http://$INSTANCE_IP/health")
if [ "$HEALTH_RESPONSE" = "OK" ]; then
    echo "✅ Health endpoint returned: $HEALTH_RESPONSE"
else
    echo "❌ Health endpoint failed. Response: $HEALTH_RESPONSE"
    exit 1
fi

# Test if page contains expected content
echo "📋 Checking page content..."
PAGE_CONTENT=$(curl -s "http://$INSTANCE_IP")
if echo "$PAGE_CONTENT" | grep -q "Welcome to Your Custom Amazon Linux AMI"; then
    echo "✅ Page contains expected welcome message"
else
    echo "❌ Page does not contain expected welcome message"
    exit 1
fi

if echo "$PAGE_CONTENT" | grep -q "Apache HTTP Server"; then
    echo "✅ Page indicates Apache is running"
else
    echo "❌ Page does not indicate Apache is running"
    exit 1
fi

# Performance test
echo "⚡ Running basic performance test..."
RESPONSE_TIME=$(curl -o /dev/null -s -w "%{time_total}\n" "http://$INSTANCE_IP")
echo "📊 Response time: ${RESPONSE_TIME}s"

if (( $(echo "$RESPONSE_TIME < 2.0" | bc -l) )); then
    echo "✅ Response time is acceptable"
else
    echo "⚠️  Response time is slower than expected"
fi

echo ""
echo "🎉 Validation Complete!"
echo "====================="
echo "✅ Web service is running correctly"
echo "✅ Health check is working"
echo "✅ Content is properly served"
echo ""
echo "🌐 Your custom AMI web service is ready to use!"
echo "   Access it at: http://$INSTANCE_IP"
