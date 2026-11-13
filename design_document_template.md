Linux+ Milestone 2 — Design Document
Student: Temesgen Tesfahunegn
GitHub Repo URL: https://github.com/temesgenbirhane/LinuxPlus_M2_Starter_Files
Date Submitted: 11/13/2026
Script filename: deploy.sh
Container image: ubuntu:22.04
---
Section 1: Create Service Account (60 pts)
What username did you choose and why?
I created a service account named `webservice` to distinguish it from a regular human user and indicate that it is intended to run a service.
useradd -r -d /var/lib/webservice -m -s /sbin/nologin webservice

What shell did you assign and why is a non-login shell required?
I assigned `/sbin/nologin` because the account does not need an interactive shell. A
login shell could allow an attacker who obtained the account's credentials to start
an interactive session and use the account for unauthorized activity.
`useradd -r -d /var/lib/webservice -m -s /sbin/nologin webservice`

What is the home directory and why that location?
I used `/var/lib/webservice` as the home directory and created it with the `-m` flag.
The `/home` directory is generally intended for regular users, whereas `/var/lib` is
intended for application and service state data. This location can store persistent
data needed by the web service.
`useradd -r -d /var/lib/webservice -m -s /sbin/nologin webservice`

What command did you use and what does each flag do?
useradd -r -d /var/lib/webservice -m -s /sbin/nologin webservice
- `-r` creates a system account, normally with a UID in the system-account range.
- `-d /var/lib/webservice` sets the home directory.
- `-m` creates the home directory if it does not exist.
- `-s /sbin/nologin` assigns a non-interactive login shell.
- `webservice` is the account name.

---
Section 2: Configure Web Root Permissions (48 pts)
What ownership did you set and why?
The `webservice` account owns the content it serves, allowing the service to manage
that content without requiring root privileges.
chown webservice /var/www/html
chown webservice /var/www/html/index.html

What permission value did you use for the directory and what does each digit mean?
The owner gets full access because the service manages the web content. Group members
and other users can read and traverse the directory but cannot write to it, preventing
unauthorized users from altering web content. Execute permission is required to
traverse the directory.
- Owner: `7` = read, write, and execute (`rwx`)
- Group: `5` = read and execute (`r-x`)
- Other: `5` = read and execute (`r-x`)


What permission value did you set on files and why?
I did not assign file permissions in this section. If needed, I would set the file
permissions explicitly with:
`chmod 644 /var/www/html/index.html`
This gives the owner read/write access and gives the group and others read access.
Web files generally should not have execute permission or be writable by everyone.
I would verify permissions and ownership with `ls -l` for files and `ls -ld` for
directories.
---
Section 3: Install Web Server Package (42 pts)
Which package did you install and why apache2?
I installed Apache with `apt-get update && apt-get install -y apache2`.
I chose Apache because it is a widely used and established web server, although
alternatives such as Nginx may be better suited for certain workloads.

What flags did you use with apt-get and what do they do in a script?
I used the `-y` flag, which automatically answers yes to package-manager prompts so
the script does not pause for interactive input. I also used `apt-get update` to
refresh the package lists before installation.
How did you verify the installation succeeded?
I used an `if` block that checks the exit status of the most recent command with `$?`.
The script terminates if the exit status is not `0`, indicating failure.
---
Section 4: Enable and Start Service (42 pts)
What systemctl commands did you write?
systemctl enable apache2
systemctl start apache2
`enable` configures Apache to start automatically during a normal system
boot. `start` attempts to start Apache immediately.

What did you observe when you ran these commands in the container?
When I attempted to start Apache2 with `systemctl`, I received: “System has not
been booted with systemd as init system (PID 1). Can't operate.” and “Failed to
connect to bus: Host is down.” This occurs because systemd is not running as PID 1
in the container.
Why does systemctl behave this way in a Docker container?
It behaves this way because Docker containers typically run an application process,
such as Apache, rather than a complete operating-system init system. As a result,
systemd is not available to manage services through `systemctl`.

What would you verify on a real production server?
systemctl status apache2
systemctl is-enabled apache2
systemctl is-active apache2
These checks verify the service configuration, enabled state, and active state. I
would also verify that Apache is serving requests by testing its HTTP response.

---
Section 5: Configure Firewall (36 pts)
What firewall tool did you use and why?
I used UFW (Uncomplicated Firewall), Ubuntu's simplified firewall interface. UFW
provides readable commands for managing the underlying firewall rules and is
available in Ubuntu 22.04.

What ports did you allow and why both 80 and 443?
ufw allow 80/tcp
ufw allow 443/tcp
I opened ports: 80 is HTTP and 443 is HTTPS. A web server needs both so browsers can connect either way. Everything else stays closed to reduce attack surface.

What did you observe when you ran ufw enable in the container?
The container reported errors while UFW attempted to run iptables, including:
ERROR: problem running iptables
ERROR: problem running ufw-init
iptables: Permission denied (you must be root)
iptables-restore: Couldn't load match `conntrack': No such file or directory
The container lacks the required network-administration capability, typically
`NET_ADMIN`, and may also lack the required kernel support for changing firewall
rules.

---
Section 6: Log Rotation Cron Job (30 pts)
What cron expression did you use and what does each field mean?
The script adds this cron entry:
`0 2 * * 0 /usr/sbin/logrotate /etc/logrotate.conf`
The expression fields are:
1. `0` — minute 0
2. `2` — hour 2, or 2:00 AM
3. `*` — every day of the month
4. `*` — every month
5. `0` — Sunday
Therefore, root runs the command every Sunday at 2:00 AM. The entry is added while
preserving the existing root crontab contents, so existing jobs are not overwritten.

What command does the cron job run and why logrotate?
It runs:
/usr/sbin/logrotate /etc/logrotate.conf
`/etc/logrotate.conf` is the main logrotate configuration file. It controls rotation frequency, retention, compression, and related behavior for configured logs.

What happens if log rotation is never configured on a production server?
Log rotation prevents log files from continuously growing. Without log rotation, logs can consume increasing amounts of disk space and
eventually fill the filesystem, which can disrupt services and prevent new data
from being written.
---
Git Commit History
Paste the output of `git log --oneline` showing at least 3 commits:
```
altered deploy.sh
725a9aa Added last touch comments for clarity
be46b2c Added appropriate documentation using github copilot
7028e08 modified comments and added few extra touches
6c35441 testing sync
1053408  Set up log rotation Section_6
8929a3c Configure firewall Section_5
a759e6d  Enable and start service Section_4
5055ed7 Changed the line endings of deploy.sh from CRLF to LF to resolve compatibility issue &  Install web server package Section_3
0200122 Re-initialize repository at parent level
75d2ebe Configure web root permissions Section_2
41cc669 Initial commit of existing local files
```
---
AI Collaboration (18 pts)
Required — AIAS Level 3. Omitting this section results in a grade deduction.
Field	Your response
Tools used	[ChatGPT, GitHub Copilot]
Prompt summary	[I asked AI why systemd is not the primary service manager in a container and how to start Apache without relying on systemd. I also asked how firewall rules work in containers, how the NET_ADMIN capability differs from a virtual machine, and how development and production configurations differ.]
Suggestions accepted	[I accepted suggestions to clarify the differences between containers and virtual machines, explain the purpose of the NET_ADMIN capability, improve the wording of the service and security explanations, terminate the script when Apache installation fails, and choose appropriate permissions for files and directories.]
Suggestions rejected	[For the firewall section, I rejected a suggestion to change my host computer's network configuration. After considering it, I decided not to use it because of its complexity and the potential security risks to my personal computer.]
