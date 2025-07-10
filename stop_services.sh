#!/bin/bash

# WP SecureScan AI - Service Stop Script
# Author: MD Ismail
# Date: July 9, 2025

echo "🛑 Stopping WP SecureScan AI Services..."
echo "========================================"

# Stop Rails server
echo "🌐 Stopping Rails server..."
pkill -f "rails server"

# Stop Sidekiq worker
echo "⚡ Stopping Sidekiq worker..."
pkill -f "sidekiq"

# Stop Redis (optional - comment out if you want to keep Redis running)
# echo "📦 Stopping Redis server..."
# pkill -x redis-server

sleep 2

echo ""
echo "✅ Services stopped successfully!"
echo ""
echo "📊 Service Status:"
echo "=================="
echo "Redis:    $(pgrep -x redis-server > /dev/null && echo '✅ Running' || echo '❌ Stopped')"
echo "Sidekiq:  $(pgrep -f sidekiq > /dev/null && echo '✅ Running' || echo '❌ Stopped')"
echo "Rails:    $(lsof -i :59246 > /dev/null && echo '✅ Running' || echo '❌ Stopped')"