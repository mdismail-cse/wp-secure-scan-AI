#!/bin/bash

# WP SecureScan AI - Service Startup Script
# Author: MD Ismail
# Date: July 9, 2025

echo "🚀 Starting WP SecureScan AI Services..."
echo "========================================"

# Check if Redis is running
if ! pgrep -x "redis-server" > /dev/null; then
    echo "📦 Starting Redis server..."
    redis-server --daemonize yes
    sleep 2
else
    echo "✅ Redis server is already running"
fi

# Check if Sidekiq is running
if ! pgrep -f "sidekiq" > /dev/null; then
    echo "⚡ Starting Sidekiq worker..."
    cd /workspace/wp-secure-scan-AI
    bundle exec sidekiq -d
    sleep 2
else
    echo "✅ Sidekiq worker is already running"
fi

# Start Rails server
echo "🌐 Starting Rails server on port 59246..."
cd /workspace/wp-secure-scan-AI
rails server -b 0.0.0.0 -p 59246 > server.log 2>&1 &

sleep 3

echo ""
echo "🎉 All services started successfully!"
echo ""
echo "📊 Service Status:"
echo "=================="
echo "Redis:    $(pgrep -x redis-server > /dev/null && echo '✅ Running' || echo '❌ Stopped')"
echo "Sidekiq:  $(pgrep -f sidekiq > /dev/null && echo '✅ Running' || echo '❌ Stopped')"
echo "Rails:    $(lsof -i :59246 > /dev/null && echo '✅ Running on port 59246' || echo '❌ Stopped')"
echo ""
echo "🌍 Application URL: https://cnoviptvtgqjeipw.staging-runtime.all-hands.dev:59246"
echo "🔧 Admin Panel: https://cnoviptvtgqjeipw.staging-runtime.all-hands.dev:59246/admin/api_keys"
echo "📊 Sidekiq Web: https://cnoviptvtgqjeipw.staging-runtime.all-hands.dev:59246/sidekiq"
echo ""
echo "👤 Default Admin Credentials:"
echo "   Email: admin@wpdeveloper.com"
echo "   Password: SecurePass123!"
echo ""
echo "📝 Logs:"
echo "   Rails: tail -f server.log"
echo "   Sidekiq: Check console output"
echo ""
echo "🛑 To stop services: ./stop_services.sh"