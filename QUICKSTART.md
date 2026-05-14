# Quick Start Guide - Log Cleanup Script

## 5-Minute Setup

### Step 1: Review the Configuration File

Open `log_cleanup_config.conf` and customize it for your environment:

```bash
vi log_cleanup_config.conf
```

Example configuration:
```
# Format: FILESYSTEM|DIRECTORY_PATH|RETENTION_DAYS|FILE_PATTERN
/home/lotprod|/home/lotprod/na/ods/outarch|30|*.log
/home/lotprod|/home/lotprod/na/ods/archive|60|*.dat
/var/log|/var/log/application|90|*.log
```

### Step 2: Update Email Address (Optional)

If you want to change the email recipient, edit the script:

```bash
vi log_cleanup.sh
# Change line: EMAIL_TO="shalensh@us.ibm.com"
```

### Step 3: Test with Dry-Run

Preview what files would be deleted WITHOUT actually deleting them:

```bash
./log_cleanup.sh --dry-run
```

This will:
- Show all files that would be deleted
- Create a deletion list file
- Send email notifications (in dry-run mode)
- NOT delete any files

### Step 4: Review the Deletion List

Check the deletion list file created in `/tmp/`:

```bash
ls -lt /tmp/files_to_delete_*.txt | head -1
cat /tmp/files_to_delete_*.txt
```

### Step 5: Run the Actual Cleanup

Once you're satisfied with the dry-run results:

```bash
./log_cleanup.sh
```

This will:
- Delete files older than the retention period
- Send email for each deleted file
- Send a summary email
- Create detailed logs

### Step 6: Check the Results

Review the log file:

```bash
ls -lt /var/log/cleanup_logs/log_cleanup_*.log | head -1
tail -100 /var/log/cleanup_logs/log_cleanup_*.log
```

## Testing with Sample Data

Use the provided test script to create sample files and test the cleanup:

```bash
# Create test files and directories
./test_cleanup.sh

# Test with dry-run
./log_cleanup.sh /tmp/log_cleanup_test/test_config.conf --dry-run

# Run actual cleanup on test files
./log_cleanup.sh /tmp/log_cleanup_test/test_config.conf

# Clean up test files
rm -rf /tmp/log_cleanup_test
```

## Scheduling with Cron

Add to crontab for automatic execution:

```bash
crontab -e
```

Add one of these lines:

```bash
# Daily at 2 AM
0 2 * * * /path/to/log_cleanup.sh /path/to/log_cleanup_config.conf

# Weekly on Sunday at 3 AM
0 3 * * 0 /path/to/log_cleanup.sh /path/to/log_cleanup_config.conf

# Monthly on the 1st at 4 AM
0 4 1 * * /path/to/log_cleanup.sh /path/to/log_cleanup_config.conf
```

## Common Commands

```bash
# Dry-run with default config
./log_cleanup.sh --dry-run

# Dry-run with custom config
./log_cleanup.sh /path/to/config.conf --dry-run

# Run cleanup with default config
./log_cleanup.sh

# Run cleanup with custom config
./log_cleanup.sh /path/to/config.conf

# View recent logs
tail -f /var/log/cleanup_logs/log_cleanup_*.log

# View deletion lists
ls -lt /tmp/files_to_delete_*.txt

# Check script permissions
ls -l log_cleanup.sh
```

## Troubleshooting Quick Fixes

### Script won't run
```bash
chmod +x log_cleanup.sh
```

### No emails received
```bash
# Test mailx
echo "Test" | mailx -s "Test" shalensh@us.ibm.com
```

### Files not being deleted
```bash
# Check permissions
ls -ld /path/to/directory
# Run dry-run to see what would be deleted
./log_cleanup.sh --dry-run
```

### Configuration errors
```bash
# Validate config file format
cat log_cleanup_config.conf | grep -v "^#" | grep -v "^$"
```

## Important Notes

⚠️ **Always test with --dry-run first!**

⚠️ **Verify the deletion list before running actual cleanup**

⚠️ **Ensure you have backups of important files**

⚠️ **Start with longer retention periods and adjust as needed**

## Need Help?

See the full README.md for detailed documentation.

Contact: shalensh@us.ibm.com