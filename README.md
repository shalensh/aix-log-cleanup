# Log File Cleanup Script for AIX

A generic, configurable shell script for cleaning up log files on AIX systems based on retention periods. The script supports multiple directories, customizable retention periods, and sends email notifications for all file deletions.

## Features

- **Configuration-based**: All settings (directories, retention periods, file patterns) are defined in a configuration file
- **Flexible retention periods**: Support for retention periods from days to years (1-365+ days)
- **Email notifications**: Sends individual emails for each deleted file plus a summary email
- **Deletion list**: Creates a comprehensive list of files to be deleted before actual deletion
- **Dry-run mode**: Preview files that would be deleted without actually deleting them
- **Filesystem monitoring**: Reports filesystem space before and after cleanup
- **Comprehensive logging**: Detailed logs of all operations
- **Error handling**: Robust error checking and reporting

## Files

- `log_cleanup.sh` - Main cleanup script
- `log_cleanup_config.conf` - Configuration file with directory and retention settings
- `README.md` - This documentation file

## Prerequisites

- AIX operating system
- Korn shell (ksh)
- `mailx` command for sending emails
- `find` command
- Appropriate permissions to delete files in target directories

## Configuration File Format

The configuration file (`log_cleanup_config.conf`) uses a pipe-delimited format:

```
FILESYSTEM|DIRECTORY_PATH|RETENTION_DAYS|FILE_PATTERN
```

### Parameters:

- **FILESYSTEM**: The filesystem mount point (e.g., `/home/lotprod`, `/var/log`)
- **DIRECTORY_PATH**: Full path to the directory containing files to clean
- **RETENTION_DAYS**: Number of days to retain files (files older than this will be deleted)
- **FILE_PATTERN**: Pattern to match files (e.g., `*.log`, `*.dat`, `*` for all files)

### Example Configuration:

```bash
# Log cleanup configuration
/home/lotprod|/home/lotprod/na/ods/outarch|30|*.log
/home/lotprod|/home/lotprod/na/ods/archive|60|*.dat
/var/log|/var/log/application|90|*.log
/opt/logs|/opt/logs/system|180|*
/tmp|/tmp/temp_logs|7|*.tmp
```

### Configuration Rules:

- Lines starting with `#` are treated as comments
- Empty lines are ignored
- Whitespace around values is automatically trimmed
- Retention days must be a positive integer

## Usage

### Basic Usage

```bash
./log_cleanup.sh [config_file]
```

If no config file is specified, it defaults to `./log_cleanup_config.conf`

### Dry-Run Mode

Preview files that would be deleted without actually deleting them:

```bash
./log_cleanup.sh --dry-run
./log_cleanup.sh log_cleanup_config.conf --dry-run
```

### Examples

```bash
# Use default configuration file
./log_cleanup.sh

# Use custom configuration file
./log_cleanup.sh /path/to/custom_config.conf

# Dry-run with default config
./log_cleanup.sh --dry-run

# Dry-run with custom config
./log_cleanup.sh /path/to/custom_config.conf --dry-run
```

## Installation

1. Copy the script and configuration files to your desired location:
   ```bash
   cp log_cleanup.sh /usr/local/bin/
   cp log_cleanup_config.conf /etc/
   ```

2. Make the script executable:
   ```bash
   chmod +x /usr/local/bin/log_cleanup.sh
   ```

3. Edit the configuration file to match your requirements:
   ```bash
   vi /etc/log_cleanup_config.conf
   ```

4. Update the email address in the script if needed:
   ```bash
   vi /usr/local/bin/log_cleanup.sh
   # Change EMAIL_TO variable to your email address
   ```

## Scheduling with Cron

To run the cleanup script automatically, add it to crontab:

```bash
# Edit crontab
crontab -e

# Run daily at 2 AM
0 2 * * * /usr/local/bin/log_cleanup.sh /etc/log_cleanup_config.conf

# Run weekly on Sunday at 3 AM
0 3 * * 0 /usr/local/bin/log_cleanup.sh /etc/log_cleanup_config.conf

# Run monthly on the 1st at 4 AM
0 4 1 * * /usr/local/bin/log_cleanup.sh /etc/log_cleanup_config.conf
```

## Output Files

### Log Files

Location: `/var/log/cleanup_logs/` (or `/tmp/` if directory creation fails)

Format: `log_cleanup_YYYYMMDD_HHMMSS.log`

Contains:
- Script execution details
- Files found and deleted
- Filesystem space information
- Errors and warnings

### Deletion List

Location: `/tmp/files_to_delete_YYYYMMDD_HHMMSS.txt`

Contains:
- List of all files identified for deletion
- File sizes and dates
- Summary information
- Organized by directory

## Email Notifications

The script sends two types of email notifications:

### 1. Individual File Deletion Emails

Sent for each file deleted, containing:
- Server hostname
- File path, size, and date
- Directory and retention period
- Timestamp of deletion

Subject: `Log File Deleted: [filename]`

### 2. Summary Email

Sent at the end of execution, containing:
- Complete deletion list
- Execution mode (ACTIVE or DRY-RUN)
- Server and configuration details
- Link to detailed log file

Subject: `Log Cleanup Summary - [hostname] - [date]`

## Customization

### Change Email Recipient

Edit the script and modify the `EMAIL_TO` variable:

```bash
EMAIL_TO="your.email@example.com"
```

### Change Log Directory

Edit the script and modify the `LOG_DIR` variable:

```bash
LOG_DIR="/your/custom/log/directory"
```

### Modify Retention Periods

Edit the configuration file and adjust the retention days for each directory:

```bash
# Change from 30 days to 60 days
/home/lotprod|/home/lotprod/na/ods/outarch|60|*.log
```

### Add New Directories

Add new lines to the configuration file:

```bash
# Add new directory with 45-day retention
/new/filesystem|/new/directory/path|45|*.log
```

## Retention Period Examples

- **7 days**: Temporary files, debug logs
- **30 days**: Standard application logs
- **60 days**: Important application logs
- **90 days**: Audit logs, compliance logs
- **180 days**: Long-term retention logs
- **365 days**: Annual retention requirements

## Troubleshooting

### Script doesn't run

1. Check if script is executable:
   ```bash
   ls -l log_cleanup.sh
   chmod +x log_cleanup.sh
   ```

2. Verify shell interpreter:
   ```bash
   which ksh
   ```

### No emails received

1. Check if mailx is installed:
   ```bash
   which mailx
   ```

2. Test email manually:
   ```bash
   echo "Test" | mailx -s "Test Subject" your.email@example.com
   ```

3. Check mail logs:
   ```bash
   tail -f /var/log/mail.log
   ```

### Files not being deleted

1. Check file permissions:
   ```bash
   ls -l /path/to/directory
   ```

2. Verify retention period calculation:
   ```bash
   find /path/to/directory -type f -name "*.log" -mtime +30
   ```

3. Run in dry-run mode to see what would be deleted:
   ```bash
   ./log_cleanup.sh --dry-run
   ```

### Configuration file errors

1. Check file format (pipe-delimited)
2. Ensure no extra spaces in retention days
3. Verify paths exist
4. Check for special characters

## Best Practices

1. **Test first**: Always run with `--dry-run` before actual deletion
2. **Start conservative**: Begin with longer retention periods and adjust as needed
3. **Monitor space**: Check filesystem space regularly
4. **Review logs**: Periodically review cleanup logs for issues
5. **Backup important files**: Ensure critical files are backed up before cleanup
6. **Schedule wisely**: Run during off-peak hours to minimize impact
7. **Document changes**: Keep track of configuration changes
8. **Test email**: Verify email notifications are working

## Security Considerations

- Script should be owned by root or appropriate system user
- Configuration file should have restricted permissions (640 or 600)
- Log directory should have appropriate permissions
- Review deletion list before running in production
- Maintain audit trail of all deletions

## Support and Maintenance

### Regular Maintenance Tasks

1. Review and update retention periods quarterly
2. Check log file growth and rotate if needed
3. Verify email notifications are being received
4. Monitor filesystem space trends
5. Update configuration for new directories

### Version History

- **v1.0** (2026-04-29): Initial release
  - Configuration-based cleanup
  - Email notifications
  - Dry-run mode
  - Deletion list generation

## License

This script is provided as-is for use in AIX environments.

## Author

Created for IBM AIX log file management.

## Contact

For issues or questions, contact: shalensh@us.ibm.com