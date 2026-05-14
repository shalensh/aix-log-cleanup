#!/bin/ksh
################################################################################
# Script Name: log_cleanup.sh
# Description: Generic log file cleanup script for AIX systems
#              Cleans files based on retention period defined in config file
#              Sends email notification for each deleted file
# Usage: ./log_cleanup.sh [config_file] [--dry-run]
#        --dry-run: List files to be deleted without actually deleting them
################################################################################

# Configuration
CONFIG_FILE="${1:-./log_cleanup_config.conf}"
DRY_RUN=0
EMAIL_TO="shalensh@us.ibm.com"
HOSTNAME=$(hostname)
LOG_DIR="/var/log/cleanup_logs"
LOG_FILE="${LOG_DIR}/log_cleanup_$(date +%Y%m%d_%H%M%S).log"
DELETION_LIST="/tmp/files_to_delete_$(date +%Y%m%d_%H%M%S).txt"

# Check for dry-run flag
if [ "$2" = "--dry-run" ] || [ "$1" = "--dry-run" ]; then
    DRY_RUN=1
    [ "$1" = "--dry-run" ] && CONFIG_FILE="${2:-./log_cleanup_config.conf}"
fi

# Initialize log directory
initialize_log() {
    if [ ! -d "${LOG_DIR}" ]; then
        mkdir -p "${LOG_DIR}" 2>/dev/null || LOG_FILE="/tmp/log_cleanup_$(date +%Y%m%d_%H%M%S).log"
    fi
}

# Log message function
log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2" | tee -a "${LOG_FILE}"
}

# Send email notification
send_email() {
    local subject="$1"
    local body="$2"
    echo "${body}" | mailx -s "${subject}" "${EMAIL_TO}"
    log_msg "INFO" "Email sent to ${EMAIL_TO}"
}

# Check filesystem space
check_space() {
    df -g "$1" 2>/dev/null | tail -1 | awk '{print "FS: "$1", Size: "$2"GB, Used: "$3"GB, Avail: "$4"GB, Use%: "$5}'
}

# Cleanup directory
cleanup_dir() {
    local filesystem="$1"
    local directory="$2"
    local retention="$3"
    local pattern="$4"
    local file_count=0
    local total_size=0
    
    log_msg "INFO" "=========================================="
    log_msg "INFO" "Processing: ${directory}"
    log_msg "INFO" "Retention: ${retention} days, Pattern: ${pattern}"
    
    if [ ! -d "${directory}" ]; then
        log_msg "WARN" "Directory not found: ${directory}"
        return 1
    fi
    
    log_msg "INFO" "Space before: $(check_space ${filesystem})"
    
    # First pass: List files to be deleted
    log_msg "INFO" "Scanning for files older than ${retention} days..."
    echo "" >> "${DELETION_LIST}"
    echo "Directory: ${directory}" >> "${DELETION_LIST}"
    echo "Retention: ${retention} days, Pattern: ${pattern}" >> "${DELETION_LIST}"
    echo "----------------------------------------" >> "${DELETION_LIST}"
    
    find "${directory}" -type f -name "${pattern}" -mtime +${retention} 2>/dev/null | while read file; do
        if [ -f "${file}" ]; then
            local size=$(ls -lh "${file}" | awk '{print $5}')
            local size_bytes=$(ls -l "${file}" | awk '{print $5}')
            local date=$(ls -l "${file}" | awk '{print $6, $7, $8}')
            
            echo "${file}|${size}|${date}|${size_bytes}" >> "${DELETION_LIST}"
            log_msg "INFO" "Found: ${file} (${size}, ${date})"
        fi
    done
    
    # Count files to be deleted
    file_count=$(grep -c "^/" "${DELETION_LIST}" 2>/dev/null || echo 0)
    
    if [ ${file_count} -eq 0 ]; then
        log_msg "INFO" "No files found for deletion in ${directory}"
        echo "No files found for deletion" >> "${DELETION_LIST}"
        echo "" >> "${DELETION_LIST}"
        return 0
    fi
    
    log_msg "INFO" "Found ${file_count} file(s) to delete"
    
    # If dry-run mode, skip deletion
    if [ ${DRY_RUN} -eq 1 ]; then
        log_msg "INFO" "DRY-RUN MODE: Files listed but not deleted"
        echo "" >> "${DELETION_LIST}"
        return 0
    fi
    
    # Second pass: Delete files
    log_msg "INFO" "Starting file deletion..."
    find "${directory}" -type f -name "${pattern}" -mtime +${retention} 2>/dev/null | while read file; do
        if [ -f "${file}" ]; then
            local size=$(ls -lh "${file}" | awk '{print $5}')
            local date=$(ls -l "${file}" | awk '{print $6, $7, $8}')
            
            rm -f "${file}" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                log_msg "INFO" "DELETED: ${file} (${size}, ${date})"
                
                # Send email for each deleted file
                local email_body="Log File Cleanup Notification
=============================
Server: ${HOSTNAME}
Time: $(date '+%Y-%m-%d %H:%M:%S')

FILE DELETED:
File: ${file}
Size: ${size}
Date: ${date}
Directory: ${directory}
Retention: ${retention} days

This file exceeded the retention period and was automatically deleted.

Script: $(basename $0)
Log: ${LOG_FILE}
Deletion List: ${DELETION_LIST}"
                
                send_email "Log File Deleted: $(basename ${file})" "${email_body}"
            else
                log_msg "ERROR" "Failed to delete: ${file}"
            fi
        fi
    done
    
    echo "" >> "${DELETION_LIST}"
    log_msg "INFO" "Space after: $(check_space ${filesystem})"
    log_msg "INFO" "=========================================="
}

# Main function
main() {
    initialize_log
    
    # Initialize deletion list file
    echo "=========================================" > "${DELETION_LIST}"
    echo "Log File Cleanup - Files to be Deleted" >> "${DELETION_LIST}"
    echo "=========================================" >> "${DELETION_LIST}"
    echo "Server: ${HOSTNAME}" >> "${DELETION_LIST}"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')" >> "${DELETION_LIST}"
    echo "Config: ${CONFIG_FILE}" >> "${DELETION_LIST}"
    if [ ${DRY_RUN} -eq 1 ]; then
        echo "Mode: DRY-RUN (No files will be deleted)" >> "${DELETION_LIST}"
    else
        echo "Mode: ACTIVE (Files will be deleted)" >> "${DELETION_LIST}"
    fi
    echo "=========================================" >> "${DELETION_LIST}"
    
    log_msg "INFO" "=========================================="
    log_msg "INFO" "Log Cleanup Script Started"
    log_msg "INFO" "Host: ${HOSTNAME}"
    log_msg "INFO" "Config: ${CONFIG_FILE}"
    log_msg "INFO" "Email: ${EMAIL_TO}"
    if [ ${DRY_RUN} -eq 1 ]; then
        log_msg "INFO" "Mode: DRY-RUN (No files will be deleted)"
    else
        log_msg "INFO" "Mode: ACTIVE (Files will be deleted)"
    fi
    log_msg "INFO" "Deletion List: ${DELETION_LIST}"
    log_msg "INFO" "=========================================="
    
    # Check prerequisites
    if [ ! -f "${CONFIG_FILE}" ]; then
        log_msg "ERROR" "Config file not found: ${CONFIG_FILE}"
        exit 1
    fi
    
    if ! command -v mailx >/dev/null 2>&1; then
        log_msg "ERROR" "mailx command not found"
        exit 1
    fi
    
    # Process configuration
    while IFS='|' read -r fs dir ret pat; do
        # Skip comments and empty lines
        echo "${fs}" | grep -q '^[[:space:]]*#' && continue
        [ -z "${fs}" ] && continue
        
        # Trim whitespace
        fs=$(echo "${fs}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        dir=$(echo "${dir}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        ret=$(echo "${ret}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        pat=$(echo "${pat}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Validate retention is numeric
        echo "${ret}" | grep -q '^[0-9]\+$' || continue
        
        cleanup_dir "${fs}" "${dir}" "${ret}" "${pat}"
    done < "${CONFIG_FILE}"
    
    # Send summary email with deletion list
    log_msg "INFO" "Sending summary email with deletion list..."
    local summary_body="Log File Cleanup Summary
=============================
Server: ${HOSTNAME}
Completion Time: $(date '+%Y-%m-%d %H:%M:%S')
Configuration: ${CONFIG_FILE}
Mode: $([ ${DRY_RUN} -eq 1 ] && echo 'DRY-RUN' || echo 'ACTIVE')

Deletion list has been generated and attached below.
For detailed logs, see: ${LOG_FILE}

========================================
DELETION LIST
========================================
$(cat ${DELETION_LIST})

This is an automated notification from the log cleanup script."
    
    send_email "Log Cleanup Summary - ${HOSTNAME} - $(date '+%Y-%m-%d')" "${summary_body}"
    
    log_msg "INFO" "=========================================="
    log_msg "INFO" "Log Cleanup Script Completed"
    log_msg "INFO" "Deletion list saved to: ${DELETION_LIST}"
    log_msg "INFO" "=========================================="
}

# Execute
main
exit 0

# Made with Bob
