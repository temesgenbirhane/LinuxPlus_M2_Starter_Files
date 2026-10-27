#!/bin/bash
# ============================================================
# Linux+ M2 — Deployment Verification Script
#
# Run this script after deploy.sh to check your work.
# Each check tells you what it is testing and why it matters.
# A PASS on all checks means your deployment meets the rubric requirements.
# A FAIL tells you specifically what to fix.
#
# USAGE: bash /opt/deploy/test_deploy.sh
# ============================================================

PASS=0
FAIL=0
WARN=0

pass() { echo "  [PASS] $1"; ((PASS++)); }
fail() { echo "  [FAIL] $1"; ((FAIL++)); }
warn() { echo "  [WARN] $1 (partial credit)"; ((WARN++)); }

echo ""
echo "============================================================"
echo " Linux+ M2 Deployment Verification"
echo " $(date)"
echo "============================================================"


# ── CHECK 1: Service Account ──────────────────────────────────
echo ""
echo "CHECK 1: Service account (Section 1)"
echo "  Testing: Does the 'webservice' account exist with correct configuration?"

if id webservice &>/dev/null; then
    pass "User 'webservice' exists"

    # Check for non-login shell
    SHELL=$(getent passwd webservice | cut -d: -f7)
    if [[ "$SHELL" == "/sbin/nologin" || "$SHELL" == "/usr/sbin/nologin" || "$SHELL" == "/bin/false" ]]; then
        pass "webservice has a non-login shell ($SHELL)"
    else
        fail "webservice shell is '$SHELL' — should be /sbin/nologin or /usr/sbin/nologin"
        echo "         Why this matters: a login shell allows interactive access to the account."
        echo "         Service accounts that run daemons should never be interactive."
    fi

    # Check home directory
    HOME_DIR=$(getent passwd webservice | cut -d: -f6)
    if [[ "$HOME_DIR" == "/var/lib/webservice" ]]; then
        pass "webservice home directory is /var/lib/webservice"
    else
        fail "webservice home directory is '$HOME_DIR' — should be /var/lib/webservice"
    fi

    # Check system account flag (UID below 1000)
    UID_VAL=$(id -u webservice)
    if [ "$UID_VAL" -lt 1000 ]; then
        pass "webservice is a system account (UID $UID_VAL < 1000)"
    else
        warn "webservice UID is $UID_VAL — system accounts typically have UID < 1000 (-r flag)"
    fi
else
    fail "User 'webservice' does not exist — Section 1 not completed"
fi


# ── CHECK 2: Web Root Permissions ────────────────────────────
echo ""
echo "CHECK 2: Web root permissions (Section 2)"
echo "  Testing: Does /var/www/html exist with correct ownership and permissions?"

if [ -d "/var/www/html" ]; then
    pass "Directory /var/www/html exists"

    # Check ownership
    OWNER=$(stat -c '%U' /var/www/html)
    if [ "$OWNER" == "webservice" ]; then
        pass "/var/www/html is owned by webservice"
    else
        fail "/var/www/html is owned by '$OWNER' — should be owned by webservice"
        echo "         Why this matters: the service account needs ownership to serve files."
    fi

    # Check permissions (should be 755)
    PERMS=$(stat -c '%a' /var/www/html)
    if [ "$PERMS" == "755" ]; then
        pass "/var/www/html permissions are $PERMS (rwxr-xr-x) — correct"
    elif [ "$PERMS" == "644" ] || [ "$PERMS" == "750" ]; then
        warn "/var/www/html permissions are $PERMS — close but not standard web root permissions"
    else
        fail "/var/www/html permissions are $PERMS — expected 755 (rwxr-xr-x)"
        echo "         Why this matters: 777 (world-writable) allows any user to modify web content."
    fi
else
    fail "/var/www/html does not exist — Section 2 not completed"
fi


# ── CHECK 3: Package Installation ────────────────────────────
echo ""
echo "CHECK 3: Web server package (Section 3)"
echo "  Testing: Is apache2 installed?"

if dpkg -l apache2 2>/dev/null | grep -q "^ii"; then
    pass "apache2 is installed"
    APACHE_VERSION=$(apache2 -v 2>/dev/null | head -1)
    echo "         Version: $APACHE_VERSION"
else
    fail "apache2 is not installed — Section 3 not completed"
    echo "         Fix: apt-get install -y apache2"
fi


# ── CHECK 4: Service Configuration ───────────────────────────
echo ""
echo "CHECK 4: Service configuration (Section 4)"
echo "  Testing: Is apache2 enabled/running? (Container behavior noted)"

# In containers, systemctl may not work. We check both ways.
if systemctl is-enabled apache2 &>/dev/null; then
    pass "apache2 is enabled to start at boot (systemctl)"
elif [ -f /etc/rc2.d/S*apache2 ] 2>/dev/null || update-rc.d -n apache2 defaults 2>/dev/null | grep -q "added"; then
    pass "apache2 is enabled via init.d (alternative to systemctl in container)"
else
    warn "Could not verify apache2 is enabled — container may limit systemctl"
    echo "         This is expected in some container environments."
    echo "         Full credit if your script contains the correct systemctl enable command"
    echo "         and your comments document why the container behaves differently."
fi

if systemctl is-active apache2 &>/dev/null; then
    pass "apache2 is active and running"
elif pgrep -x apache2 &>/dev/null || pgrep -x httpd &>/dev/null; then
    pass "apache2 process is running (verified via pgrep)"
else
    warn "apache2 is not currently running — container systemd limitation may apply"
    echo "         Full credit if script contains correct systemctl start and you documented"
    echo "         the container behavior in your comments."
fi


# ── CHECK 5: Firewall Rules ───────────────────────────────────
echo ""
echo "CHECK 5: Firewall configuration (Section 5)"
echo "  Testing: Are HTTP and HTTPS ports allowed?"

# ufw may not work in all container configurations
UFW_STATUS=$(ufw status 2>/dev/null)
if echo "$UFW_STATUS" | grep -Eq "80/tcp.*ALLOW|Apache.*ALLOW"; then
    pass "Port 80/tcp (HTTP) is allowed in firewall"
else
    warn "Port 80/tcp not confirmed in ufw — container may limit ufw"
    echo "         Full credit if script contains correct ufw commands and documents container behavior."
fi

if echo "$UFW_STATUS" | grep -Eq "443/tcp.*ALLOW|Apache Full.*ALLOW"; then
    pass "Port 443/tcp (HTTPS) is allowed in firewall"
else
    warn "Port 443/tcp not confirmed in ufw — container may limit ufw"
fi

# Also check iptables directly as fallback
if iptables -L INPUT -n 2>/dev/null | grep -qE "dpt:80|dpt:443"; then
    pass "HTTP/HTTPS rules confirmed in iptables"
fi


# ── CHECK 6: Log Rotation Cron Job ───────────────────────────
echo ""
echo "CHECK 6: Log rotation cron job (Section 6)"
echo "  Testing: Is a cron job configured for log rotation?"

if crontab -l 2>/dev/null | grep -q "logrotate"; then
    pass "Log rotation cron job found in root crontab"
    CRON_ENTRY=$(crontab -l 2>/dev/null | grep logrotate)
    echo "         Entry: $CRON_ENTRY"
elif [ -f /etc/cron.weekly/logrotate ] || ls /etc/cron.d/*logrotate* 2>/dev/null; then
    pass "Logrotate found in system cron directory"
else
    fail "No log rotation cron job found — Section 6 not completed"
    echo '         Fix: (crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/sbin/logrotate /etc/logrotate.conf") | crontab -'  
fi


# ── CHECK 7: Deploy Log File ──────────────────────────────────
echo ""
echo "CHECK 7: Deployment log (logging function)"
echo "  Testing: Did the script write to /var/log/deploy.log?"

if [ -f /var/log/deploy.log ]; then
    LINES=$(wc -l < /var/log/deploy.log)
    if [ "$LINES" -gt 5 ]; then
        pass "deploy.log exists with $LINES entries"
        echo "         Last 3 entries:"
        tail -3 /var/log/deploy.log | sed 's/^/           /'
    else
        warn "deploy.log exists but has only $LINES entries — expected more logging"
    fi
else
    fail "/var/log/deploy.log not found — log() function not used or LOG_FILE path wrong"
fi


# ── SUMMARY ──────────────────────────────────────────────────
echo ""
echo "============================================================"
echo " RESULTS"
echo "  PASS: $PASS"
echo "  WARN: $WARN  (partial credit — document behavior in comments)"
echo "  FAIL: $FAIL"
echo ""

TOTAL=$((PASS + WARN + FAIL))
if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
    echo "  All checks passed. Your deployment meets the rubric requirements."
    echo "  Submit: GitHub repo URL + screenshot of this output + git log --oneline"
elif [ "$FAIL" -eq 0 ]; then
    echo "  No hard failures. WARNs on systemctl/ufw are expected in containers."
    echo "  Ensure your script code is correct and your comments document the behavior."
    echo "  Submit: GitHub repo URL + screenshot of this output + git log --oneline"
else
    echo "  Fix the FAIL items before submitting."
    echo "  Re-run this script after each fix."
fi
echo "============================================================"
echo ""