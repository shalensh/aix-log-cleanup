#!/bin/ksh
################################################################################
# Script Name: test_cleanup.sh
# Description: Test script to create sample log files and test the cleanup
# Usage: ./test_cleanup.sh
################################################################################

echo "=========================================="
echo "Log Cleanup Test Script"
echo "=========================================="

# Create test directory structure
TEST_BASE="/tmp/log_cleanup_test"
TEST_DIR1="${TEST_BASE}/app_logs"
TEST_DIR2="${TEST_BASE}/system_logs"
TEST_DIR3="${TEST_BASE}/temp_logs"

echo "Creating test directories..."
mkdir -p "${TEST_DIR1}" "${TEST_DIR2}" "${TEST_DIR3}"

# Function to create test files with specific ages
create_test_file() {
    local dir="$1"
    local filename="$2"
    local days_old="$3"
    
    local filepath="${dir}/${filename}"
    echo "Test log entry - $(date)" > "${filepath}"
    
    # Set file modification time to X days ago
    touch -t $(date -v-${days_old}d +%Y%m%d%H%M.%S 2>/dev/null || date -d "${days_old} days ago" +%Y%m%d%H%M.%S) "${filepath}" 2>/dev/null
    
    echo "Created: ${filepath} (${days_old} days old)"
}

echo ""
echo "Creating test log files..."
echo ""

# Create files in app_logs (30-day retention test)
echo "App Logs Directory (30-day retention):"
create_test_file "${TEST_DIR1}" "app_20240101.log" 90
create_test_file "${TEST_DIR1}" "app_20240315.log" 45
create_test_file "${TEST_DIR1}" "app_20240401.log" 28
create_test_file "${TEST_DIR1}" "app_20240415.log" 14
create_test_file "${TEST_DIR1}" "app_current.log" 1

echo ""
echo "System Logs Directory (60-day retention):"
create_test_file "${TEST_DIR2}" "system_20240101.log" 120
create_test_file "${TEST_DIR2}" "system_20240201.log" 88
create_test_file "${TEST_DIR2}" "system_20240315.log" 45
create_test_file "${TEST_DIR2}" "system_20240401.log" 28
create_test_file "${TEST_DIR2}" "system_current.log" 1

echo ""
echo "Temp Logs Directory (7-day retention):"
create_test_file "${TEST_DIR3}" "temp_20240101.tmp" 90
create_test_file "${TEST_DIR3}" "temp_20240415.tmp" 14
create_test_file "${TEST_DIR3}" "temp_20240422.tmp" 7
create_test_file "${TEST_DIR3}" "temp_20240425.tmp" 4
create_test_file "${TEST_DIR3}" "temp_current.tmp" 1

# Create test configuration file
TEST_CONFIG="${TEST_BASE}/test_config.conf"
echo ""
echo "Creating test configuration file: ${TEST_CONFIG}"

cat > "${TEST_CONFIG}" << EOF
# Test Configuration for Log Cleanup
# Format: FILESYSTEM|DIRECTORY_PATH|RETENTION_DAYS|FILE_PATTERN

# App logs - 30 day retention
/tmp|${TEST_DIR1}|30|*.log

# System logs - 60 day retention
/tmp|${TEST_DIR2}|60|*.log

# Temp logs - 7 day retention
/tmp|${TEST_DIR3}|7|*.tmp
EOF

echo ""
echo "=========================================="
echo "Test Setup Complete!"
echo "=========================================="
echo ""
echo "Test directories created:"
echo "  - ${TEST_DIR1}"
echo "  - ${TEST_DIR2}"
echo "  - ${TEST_DIR3}"
echo ""
echo "Test configuration: ${TEST_CONFIG}"
echo ""
echo "To test the cleanup script:"
echo ""
echo "1. DRY-RUN (preview only):"
echo "   ./log_cleanup.sh ${TEST_CONFIG} --dry-run"
echo ""
echo "2. ACTUAL CLEANUP:"
echo "   ./log_cleanup.sh ${TEST_CONFIG}"
echo ""
echo "Expected results:"
echo "  - App logs: Files older than 30 days should be deleted (2 files)"
echo "  - System logs: Files older than 60 days should be deleted (2 files)"
echo "  - Temp logs: Files older than 7 days should be deleted (2 files)"
echo ""
echo "To clean up test files:"
echo "   rm -rf ${TEST_BASE}"
echo ""
echo "=========================================="

# Made with Bob
