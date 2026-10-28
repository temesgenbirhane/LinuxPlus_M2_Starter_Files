# Linux+ Milestone 2 — Design Document

**Student:** Temesgen Tesfahunegn
**GitHub Repo URL:** [github.com/temesgenbirhane/LinuxPlus_M2_Starter_Files](https://github.com/temesgenbirhane/LinuxPlus_M2_Starter_Files)
**Date Submitted:** October 28, 2026
**Script filename:** `deploy.sh`

**Container image:** `ubuntu:22.04`

---

## Section 1: Create Service Account (60 pts)

**What username did you choose and why?**

I chose `webservice`. It identifies the account's purpose and separates the
web-server service from normal human users. A dedicated service account
limits the permissions and access available to the web-server process.

**What shell did you assign and why is a non-login shell required?**

I assigned `/sbin/nologin` with `-s /sbin/nologin`. The account only needs to
own service files; it does not need interactive shell access. A login shell
could allow an attacker who obtained the account's credentials to start an
interactive session and use the account for unauthorized activity. A
non-login shell prevents that type of access while still allowing the
service to use the account.

**What is the home directory and why that location?**

The home directory is `/var/lib/webservice`. `/var/lib` is intended for
persistent application and service state, so it is more appropriate for a
service account than a human user's directory under `/home`.

**What command did you use and what does each flag do?**

```bash
useradd -r -d /var/lib/webservice -m -s /sbin/nologin webservice
```

- `-r` creates a system account, normally with a UID in the system-account
  range.
- `-d /var/lib/webservice` sets the home directory.
- `-m` creates the home directory if it does not exist.
- `-s /sbin/nologin` assigns a non-interactive login shell.
- `webservice` is the account name.

The script first runs `id webservice` and only creates the account when it
does not already exist, making repeated runs safer.

---

## Section 2: Configure Web Root Permissions (48 pts)

**What ownership did you set and why?**

The script runs:

```bash
chown webservice /var/www/html
chown webservice /var/www/html/index.html
```

The `webservice` account owns the web root and placeholder page because the
service account is responsible for the web content. This avoids assigning
ownership to an unrelated human account and keeps the deployment ownership
consistent.

**What permission value did you use for the directory and what does each digit mean?**

The directory uses:

```bash
chmod 755 /var/www/html
```

`755` means:

- Owner: `7` = read, write, and execute (`rwx`)
- Group: `5` = read and execute (`r-x`)
- Other: `5` = read and execute (`r-x`)

Directories need execute permission so users and processes can access files
inside them. The web root is not `777` because world write permission would
allow any local user or compromised process to add, replace, or deface
served content.

**What permission value did you set on files and why?**

The script does not call `chmod` explicitly for `index.html`. The file is
created by shell redirection and normally receives `644` permissions under
the standard Ubuntu umask: owner read/write and group/other read-only. The
file is then assigned to `webservice` with `chown`.

Files generally should not have directory execute permission, and served
content should not be writable by everyone. On a production deployment I
would explicitly enforce `chmod 644 /var/www/html/index.html` if a fixed
file mode were required rather than relying on the process umask.

---

## Section 3: Install Web Server Package (42 pts)

**Which package did you install and why apache2?**

I installed `apache2`, the Apache HTTP Server package required for this
assignment. Apache is a mature, widely supported web server available in
Ubuntu's standard package repositories.

The script uses `apt-get` rather than the interactive `apt` command because
`apt-get` is intended for stable, scriptable package-management operations.

**What flags did you use with apt-get and what do they do in a script?**

The script runs:

```bash
apt-get update && apt-get install -y apache2
```

`apt-get update` refreshes the package index before installation. The `-y`
flag automatically answers yes to package-manager prompts so the script
does not pause for interactive input. The Dockerfile sets
`DEBIAN_FRONTEND=noninteractive`, which prevents Debian package
configuration dialogs from blocking automated installation.

**How did you verify the installation succeeded?**

The script checks the exit status immediately after the update/install
command. An exit status of `0` means the command succeeded. A non-zero
status is logged as `Failed to install apache2`, and the script exits with
status `1` instead of continuing with an incomplete deployment. The
verification script also checks that `dpkg -l apache2` reports the package
as installed.

---

## Section 4: Enable and Start Service (42 pts)

**What systemctl commands did you write?**

```bash
systemctl enable apache2
systemctl start apache2
```

`enable` configures Apache to start automatically during a normal system
boot. `start` attempts to start Apache immediately. Both are needed on a
regular system when the service should run now and after future reboots.

**What did you observe when you ran these commands in the container?**

The script documents that the container reported:

```text
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

This is a container limitation rather than a replacement for the required
production commands.

**Why does systemctl behave this way in a Docker container?**

`systemctl` communicates with the systemd service manager. This container
does not run systemd as process ID 1; Docker normally starts the configured
application process instead of a complete operating-system init system.
Without systemd running as PID 1, there is no systemd bus for `systemctl`
to contact. A production server with systemd as PID 1 should support these
commands normally.

**What would you verify on a real production server?**

I would run:

```bash
systemctl status apache2
systemctl is-enabled apache2
systemctl is-active apache2
ps aux | grep '[a]pache2'
curl --fail http://localhost/
```

These checks verify the service's configuration, enabled state, active
state, running processes, and HTTP response.

---

## Section 5: Configure Firewall (36 pts)

**What firewall tool did you use and why?**

I used UFW (Uncomplicated Firewall), Ubuntu's simplified firewall
interface. UFW provides readable commands for managing the underlying
iptables rules and is available for Ubuntu 22.04.

**What ports did you allow and why both 80 and 443?**

The script runs:

```bash
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

Port `80/tcp` allows HTTP traffic and port `443/tcp` allows HTTPS traffic.
Both are included because a web server may receive plain HTTP requests or
serve encrypted HTTPS connections. The `--force` option avoids the
interactive confirmation prompt, which would otherwise block automation.
The intended default policy is to deny unsolicited incoming traffic while
allowing outgoing traffic, with the web ports added as explicit exceptions.

**What did you observe when you ran ufw enable in the container?**

The container reported errors while UFW attempted to run iptables, including:

```text
ERROR: problem running iptables
ERROR: problem running ufw-init
iptables: Permission denied (you must be root)
iptables-restore: Couldn't load match `conntrack': No such file or directory
```

The container lacks the required network-administration capability
(typically `NET_ADMIN`) for changing firewall rules. On a real Ubuntu
server, I would verify the result with `ufw status verbose` and confirm
that ports 80 and 443 are allowed. I would also allow SSH port 22 when
remote administration is required.

---

## Section 6: Log Rotation Cron Job (30 pts)

**What cron expression did you use and what does each field mean?**

The script adds:

```cron
0 2 * * 0 /usr/sbin/logrotate /etc/logrotate.conf
```

The expression fields are:

1. `0` — minute 0
2. `2` — hour 2, or 2:00 AM
3. `*` — every day of the month
4. `*` — every month
5. `0` — Sunday

Therefore, root runs the command every Sunday at 2:00 AM. The entry is
added with the existing root crontab contents so existing jobs are not
overwritten.

**What command does the cron job run and why logrotate?**

It runs:

```bash
/usr/sbin/logrotate /etc/logrotate.conf
```

`/etc/logrotate.conf` is the main logrotate configuration file. It
controls rotation frequency, retention, compression, and related behavior
for configured logs. Logrotate periodically renames or compresses old logs
and removes files beyond the retention policy.

**What happens if log rotation is never configured on a production server?**

Logs can grow indefinitely, consume available disk space, and eventually
fill the filesystem. A full filesystem can cause services to fail, prevent
new logs from being written, reduce system reliability, and make incident
investigation more difficult. Rotation preserves useful history while
controlling disk usage.

---

## Git Commit History

The repository contains more than three meaningful commits. Recent output
from `git log --oneline` is:

```text
7028e08 modified comments and added few extra touches
6c35441 testing sync
1053408 Set up log rotation Section_6
8929a3c Configure firewall Section_5
a759e6d Enable and start service Section_4
5055ed Changed the line endings of deploy.sh from CRLF to LF to resolve compatibility issue & Install web server package Section_3
0200122 Re-initialize repository at parent level
75d2ebe Configure web root permissions Section_2
41cc669 Initial commit of existing local files
```

---

## AI Collaboration (18 pts)

**Required — AIAS Level 3.**

| Field | Your response |
|---|---|
| **Tools used** | GitHub Copilot, an AI assistant using Copilot SDK in VS Code |
| **Prompt summary** | I asked the AI to review the completed Milestone 2 Bash deployment script and use its actual behavior to complete the project documentation. The review covered the `webservice` account, web-root ownership and permissions, Apache installation, `systemctl` behavior, UFW rules and container limitations, weekly log rotation, and the repository commit history. |
| **Suggestions accepted** | I accepted the recommendation to document the security rationale for the non-login service account, explain each permission digit in `755`, describe the `systemctl` and UFW container limitations, explain the cron expression field by field, and record the exact commands and production verification steps. I also accepted documenting that `index.html` uses the normal file-creation umask because the script does not explicitly run `chmod` on the file. |
| **Suggestions rejected** | No code suggestion was accepted without comparing it with the existing script. The documentation does not claim that Apache or UFW succeeded in the container when the script records systemd and iptables limitations. It also does not claim that a fixed file mode was explicitly set when `deploy.sh` relies on the default umask for `index.html`. |
