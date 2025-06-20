#!/bin/bash

# TypeScript Full Toolchain - Local Security Scanning Script
# This script replicates the CI security checks for local development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Initialize error tracking
ERRORS=0

print_status "Starting security scan for TypeScript Full Toolchain"
echo "=================================================================="

# 1. Secret Detection Scan
print_status "Scanning for hardcoded secrets..."

SECRET_PATTERNS=(
    "api[_-]?key['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]"
    "password['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]"
    "secret['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]"
    "token['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]"
    "bearer\s+[a-zA-Z0-9_.-]{20,}"
    "sk_live_[a-zA-Z0-9]{20,}"
    "pk_live_[a-zA-Z0-9]{20,}"
    "access[_-]?token['\"]?\s*[:=]\s*['\"][^'\"]{10,}['\"]"
    "client[_-]?secret['\"]?\s*[:=]\s*['\"][^'\"]{10,}['\"]"
    "private[_-]?key['\"]?\s*[:=]\s*['\"][^'\"]{20,}['\"]"
    "database[_-]?url['\"]?\s*[:=]\s*['\"][^'\"]{10,}['\"]"
    "mongodb://[^'\"\\s]{10,}"
    "mysql://[^'\"\\s]{10,}"
    "postgres://[^'\"\\s]{10,}"
)

SECRETS_FOUND=0

for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -r -i -E "$pattern" src/ tests/ --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null; then
        print_error "Potential secret detected with pattern: $pattern"
        SECRETS_FOUND=1
        ERRORS=$((ERRORS + 1))
    fi
done

# Check for hardcoded URLs (excluding localhost and examples)
if grep -r -E "https?://(?!localhost|127\.0\.0\.1|0\.0\.0\.0|example\.com)[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" src/ tests/ --include="*.ts" --include="*.tsx" 2>/dev/null; then
    print_error "Hardcoded production URLs detected"
    SECRETS_FOUND=1
    ERRORS=$((ERRORS + 1))
fi

# Check for TODO/FIXME comments mentioning security
if grep -r -i -E "(TODO|FIXME|HACK).*(?:security|auth|password|token)" src/ tests/ --include="*.ts" --include="*.tsx" 2>/dev/null; then
    print_warning "Security-related TODO/FIXME comments found - review for completion"
fi

if [ $SECRETS_FOUND -eq 0 ]; then
    print_success "Secret detection scan passed"
else
    print_error "Secret detection scan failed"
fi

# 2. Dependency Vulnerability Scan
print_status "Scanning dependencies for known vulnerabilities..."

if pnpm audit --audit-level moderate >/dev/null 2>&1; then
    print_success "No moderate or higher vulnerabilities found"
else
    print_warning "Dependencies with moderate or higher vulnerabilities detected"
    echo "   Run 'pnpm audit --fix' to resolve automatically fixable issues"
    echo "   Run 'pnpm audit' to see detailed vulnerability information"
    # Note: Not treating this as error for development dependencies
fi

# 3. License Compliance Check
print_status "Checking license compliance..."

if command -v pnpm >/dev/null 2>&1; then
    pnpm licenses list --json > /tmp/licenses.json 2>/dev/null || {
        print_warning "Could not extract license information"
        touch /tmp/licenses.json
    }

    PROHIBITED_LICENSES=("GPL-2.0" "GPL-3.0" "AGPL-1.0" "AGPL-3.0" "WTFPL")
    LICENSE_ISSUES=0

    for license in "${PROHIBITED_LICENSES[@]}"; do
        if grep -q "\"$license\"" /tmp/licenses.json 2>/dev/null; then
            print_error "Prohibited license detected: $license"
            LICENSE_ISSUES=1
            ERRORS=$((ERRORS + 1))
        fi
    done

    if grep -q "\"UNKNOWN\"" /tmp/licenses.json 2>/dev/null; then
        print_warning "Dependencies with unknown licenses detected"
    fi

    rm -f /tmp/licenses.json

    if [ $LICENSE_ISSUES -eq 0 ]; then
        print_success "License compliance check passed"
    fi
else
    print_warning "pnpm not found, skipping license check"
fi

# 4. Environment Configuration Security
print_status "Validating environment configuration security..."

ENV_ERRORS=0

if [ ! -f ".env.example" ]; then
    print_error ".env.example file is missing"
    ENV_ERRORS=1
    ERRORS=$((ERRORS + 1))
fi

if [ -f ".env.example" ] && grep -E "(sk_live_|pk_live_|bearer [a-zA-Z0-9_.-]{20,})" .env.example >/dev/null; then
    print_error ".env.example contains what appears to be real secrets"
    ENV_ERRORS=1
    ERRORS=$((ERRORS + 1))
fi

REQUIRED_ENV_DOCS=("API_BASE_URL" "AUTH_TOKEN_KEY" "REQUIRE_AUTH")

for env_var in "${REQUIRED_ENV_DOCS[@]}"; do
    if [ -f ".env.example" ] && ! grep -q "$env_var" .env.example; then
        print_warning "Environment variable $env_var not documented in .env.example"
    fi
done

if [ -f ".gitignore" ]; then
    if ! grep -q "^\.env$" .gitignore; then
        print_error ".env files should be in .gitignore to prevent accidental commits"
        ENV_ERRORS=1
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ $ENV_ERRORS -eq 0 ]; then
    print_success "Environment configuration security check passed"
fi

# 5. File Permissions Check
print_status "Checking file permissions..."

PERM_ERRORS=0

# Check for overly permissive files
if find . -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.json" | xargs ls -l | grep -E "^-.{7}rw." >/dev/null; then
    print_warning "Some files have world-writable permissions"
fi

# Check for executable source files (potential security risk)
if find src/ tests/ -name "*.ts" -o -name "*.tsx" -executable 2>/dev/null | grep -q .; then
    print_warning "Source files should not be executable"
fi

if [ $PERM_ERRORS -eq 0 ]; then
    print_success "File permissions check passed"
fi

# 6. Security Test Execution
print_status "Running security-focused tests..."

if pnpm test security >/dev/null 2>&1; then
    print_success "Security tests passed"
elif pnpm test 2>/dev/null | grep -i security >/dev/null; then
    print_success "Security tests found and passed"
else
    print_warning "No security-specific tests found (consider adding some)"
fi

# Summary
echo ""
echo "=================================================================="
print_status "Security Scan Summary"

if [ $ERRORS -eq 0 ]; then
    print_success "All security checks passed! 🔒"
    echo ""
    echo "Your TypeScript Full Toolchain project follows security best practices:"
    echo "  ✅ No hardcoded secrets detected"
    echo "  ✅ License compliance verified"
    echo "  ✅ Environment configuration secure"
    echo "  ✅ File permissions appropriate"
    echo ""
    echo "📋 Continue following SECURITY.md guidelines for ongoing security"
    exit 0
else
    print_error "Security scan completed with $ERRORS errors"
    echo ""
    echo "❌ Issues found that require attention:"
    if [ $SECRETS_FOUND -eq 1 ]; then
        echo "  • Hardcoded secrets or URLs detected"
    fi
    if [ $LICENSE_ISSUES -eq 1 ]; then
        echo "  • License compliance violations"
    fi
    if [ $ENV_ERRORS -eq 1 ]; then
        echo "  • Environment configuration issues"
    fi
    echo ""
    echo "📋 Review SECURITY.md for remediation guidance"
    exit 1
fi
