# Log files grow indefinitely without rotation. Log rotation compresses
# old logs and removes files beyond a retention limit.
# A cron job schedules this task to run automatically.
#
# TODO: Add a cron job that runs logrotate weekly
#       The cron job should run as root (add to root's crontab)
#       Cron syntax: minute hour day month weekday command
#       For weekly: 0 2 * * 0 (2am every Sunday)
#       Command: /usr/sbin/logrotate /etc/logrotate.conf
#
# TODO: Log a confirmation that the cron entry was added
#
# TODO: Add comments explaining:
#         - What happens if log rotation is never configured?
#         - What does each field in the cron expression mean?
#         - What is /etc/logrotate.conf and what does it control?
#
# HINT: To add a cron job from a script without overwriting existing crontab:
#       (crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/sbin/logrotate /etc/logrotate.conf") | crontab -
