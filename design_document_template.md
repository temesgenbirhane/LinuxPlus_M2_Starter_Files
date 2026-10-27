# Linux+ Milestone 2 — Design Document

**Student:** [Your Full Name]  
**GitHub Repo URL:** [github.com/yourusername/linux-plus-milestones]  
**Date Submitted:** [Date]  
**Script filename:** deploy.sh  
**Container image:** ubuntu:22.04  

---

## Section 1: Create Service Account (60 pts)

**What username did you choose and why?**

[Your answer]

**What shell did you assign and why is a non-login shell required?**

[Your answer — exact shell path, and the security reason for no interactive login]

**What is the home directory and why that location?**

[Your answer — and why that path makes sense for a service account]

**What command did you use and what does each flag do?**

[Your answer — explain each useradd flag you used]

---

## Section 2: Configure Web Root Permissions (48 pts)

**What ownership did you set and why?**

[Your answer — chown command, and why the webservice account should own these files]

**What permission value did you use for the directory and what does each digit mean?**

[Your answer — e.g. 755 = owner rwx, group rx, other rx — and why not 777]

**What permission value did you set on files and why?**

[Your answer — and why files should typically have different permissions than directories]

---

## Section 3: Install Web Server Package (42 pts)

**Which package did you install and why apache2?**

[Your answer — apache2 is required for this assignment; explain why apt-get not just apt]

**What flags did you use with apt-get and what do they do in a script?**

[Your answer — -y flag, DEBIAN_FRONTEND=noninteractive, and why these matter in automation]

**How did you verify the installation succeeded?**

[Your answer — exit code check, dpkg -l, or other method]

---

## Section 4: Enable and Start Service (42 pts)

**What systemctl commands did you write?**

[Your answer — the exact systemctl enable and systemctl start commands]

**What did you observe when you ran these commands in the container?**

[Your answer — exact output or error message you saw. Honesty here is graded.]

**Why does systemctl behave this way in a Docker container?**

[Your answer — PID 1, systemd, container init explanation]

**What would you verify on a real production server?**

[Your answer — systemctl status, ps aux, curl localhost, etc.]

---

## Section 5: Configure Firewall (36 pts)

**What firewall tool did you use and why?**

[Your answer — ufw and why it is available in Ubuntu 22.04]

**What ports did you allow and why both 80 and 443?**

[Your answer — HTTP vs HTTPS, why both are needed for a web server]

**What did you observe when you ran ufw enable in the container?**

[Your answer — output or errors, any container-specific behavior]

---

## Section 6: Log Rotation Cron Job (30 pts)

**What cron expression did you use and what does each field mean?**

[Your answer — minute hour day month weekday, and your chosen schedule]

**What command does the cron job run and why logrotate?**

[Your answer — /usr/sbin/logrotate /etc/logrotate.conf and what logrotate does]

**What happens if log rotation is never configured on a production server?**

[Your answer — disk filling, performance impact, log loss]

---

## Git Commit History

Paste the output of `git log --oneline` showing at least 3 commits:

```
[paste git log --oneline output here]
```

---

## AI Collaboration (18 pts)

**Required — AIAS Level 3. Omitting this section results in a grade deduction.**

| Field | Your response |
|---|---|
| **Tools used** | [Name the specific tool(s): Claude, ChatGPT, GitHub Copilot, etc.] |
| **Prompt summary** | [What you asked the AI to do — be specific about which script sections] |
| **Suggestions accepted** | [What AI suggested that improved your script, why you accepted it, how you verified it worked in the container] |
| **Suggestions rejected** | [What AI got wrong, gave outdated syntax for, or suggested that did not work — and why you rejected it] |

