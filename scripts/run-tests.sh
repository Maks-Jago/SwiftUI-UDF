#!/bin/bash

# UDF Test Runner Script
# Runs the same checks as CI locally

set -e

echo "🧪 UDF Framework - Local Test Runner"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    print_error "Package.swift not found. Please run from project root."
    exit 1
fi

print_status "Starting UDF test suite..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf .build
print_status "Build cache cleaned"

# Resolve dependencies
echo "📦 Resolving package dependencies..."
swift package resolve
print_status "Dependencies resolved"

# Build debug
echo "🔨 Building debug configuration..."
swift build -c debug
print_status "Debug build successful"

# Build release
echo "🚀 Building release configuration..."
swift build -c release  
print_status "Release build successful"

# Run tests
echo "🧪 Running test suite..."
swift test --parallel --enable-code-coverage
print_status "All tests passed!"

# Check for common issues
echo "🔍 Running additional checks..."

# Check for TODO/FIXME comments
if grep -r "TODO\|FIXME" UDF/ --include="*.swift" > /dev/null 2>&1; then
    print_warning "Found TODO/FIXME comments in code"
    grep -r "TODO\|FIXME" UDF/ --include="*.swift" | head -5
else
    print_status "No TODO/FIXME comments found"
fi

# Check for print statements (shouldn't be in production code)
if grep -r "print(" UDF/ --include="*.swift" > /dev/null 2>&1; then
    print_warning "Found print statements in production code"
    grep -r "print(" UDF/ --include="*.swift" | head -3
else
    print_status "No print statements in production code"
fi

# Validate package structure
echo "📋 Validating package structure..."
if swift package diagnose-api-breaking-changes --allow-module-with-test-only-api > /dev/null 2>&1; then
    print_status "Package structure is valid"
else
    print_warning "Package structure validation had warnings"
fi

echo ""
echo "=================================="
print_status "All checks completed successfully!"
echo ""
echo "Ready to push to GitHub! 🚀"
echo ""
echo "To run individual commands:"
echo "  swift build                    # Build only"
echo "  swift test                     # Test only"  
echo "  swift test --parallel          # Parallel tests"
echo "  swift package diagnose-api-breaking-changes  # Validate API"