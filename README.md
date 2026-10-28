# Linux+ XK0-006 Milestone 2

**Student:** Temesgen Tesfahunegn
**Course:** CompTIA Linux+ XK0-006 — FastForward Track
**Year:** 2025–2026
**Date:** October 28, 2026

---

## Repository Contents

```
LinuxPlus_M2_Starter_Files/
├── README.md
├── Dockerfile
├── INSTRUCTIONS.txt
├── run_container.sh
├── test_deploy.sh
├── deploy.sh
└── design_document_template.md
```

`Dockerfile`, `run_container.sh`, and `test_deploy.sh` provide the Ubuntu
22.04 container environment and verification checks. `deploy.sh` is the
completed Milestone 2 deployment script. The design document template
contains the detailed rationale for each section of the deployment.

---

## Milestone 2 — Bash Server Deployment Script

### What my script does

`deploy.sh` deploys and hardens the basic web-server role in an Ubuntu 22.04
container. It creates the `webservice` system account with the
`/sbin/nologin` shell and `/var/lib/webservice` home directory, then creates
`/var/www/html` with `webservice` ownership and `755` permissions. The script
updates the package index, installs Apache2 non-interactively, and writes a
placeholder `index.html` owned by the service account.

The script also writes the correct `systemctl enable apache2` and
`systemctl start apache2` commands, allows HTTP and HTTPS through UFW, and
adds a root cron job to run logrotate every Sunday at 2:00 AM. All major
actions are recorded in `/var/log/deploy.log`.

### Container environment

- Base image: `ubuntu:22.04`
- Start the container: `bash run_container.sh`
- Run the deployment inside the container: `bash /opt/deploy/deploy.sh`
- Run verification inside the container: `bash /opt/deploy/test_deploy.sh`

### Key decisions

1. **Restricted service account:** The `webservice` account is a system
   account with `/sbin/nologin`, preventing interactive logins if the service
   account is compromised.
2. **Least-privilege web-root permissions:** `/var/www/html` uses `755`
   permissions. The service account can manage the web root, while group and
   other users can read and access it but cannot modify web content.
3. **Safe automation:** Existing users and files are preserved where
   possible, package installation uses `apt-get -y`, and the logrotate entry
   is appended without overwriting existing root cron jobs.
4. **Container limitations documented:** The script includes the production
   `systemctl` commands, but the container reports that systemd is not
   running as PID 1. UFW likewise cannot apply iptables rules without the
   container's required network administration capability. These commands
   should be verified on a real Ubuntu server.

### AI collaboration summary

AI assistance was used to review the deployment requirements, check that the
script comments explain the security rationale behind each command, and
organize this README around the implemented sections. The deployment was
then checked against the supplied verification script and the documented
container behavior was retained rather than treating container warnings as
successful service or firewall checks.

---

## Milestone 1



---

## Commit History

The repository history records the work by deployment section, including
service configuration, firewall rules, log rotation, and final comment
updates. View the complete history with:

```bash
git log --oneline
```

Recent commits include:

```text
7028e08 modified comments and added few extra touches
6c35441 testing sync
1053408 Set up log rotation Section_6
8929a3c Configure firewall Section_5
a759e6d Enable and start service Section_4
5055ed Install web server package Section_3
75d2ebe Configure web root permissions Section_2
```
