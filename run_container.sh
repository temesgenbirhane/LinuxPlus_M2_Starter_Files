#!/bin/bash
# ============================================================
# Linux+ M2 — Container Launcher
# Run this script from your linux-plus-milestones repo directory
# It builds the container image and drops you into a bash shell
# ============================================================

IMAGE_NAME="linuxplus-m2"

echo "[*] Building container image from Dockerfile..."
echo "    This takes 1-2 minutes on first run. Subsequent runs are faster."
docker build -t $IMAGE_NAME .

if [ $? -ne 0 ]; then
    echo "[!] Docker build failed. Check that Docker Desktop is running."
    echo "    If on macOS Apple Silicon, try: docker build --platform linux/amd64 -t $IMAGE_NAME ."
    exit 1
fi

echo "[*] Starting container..."
echo "    Your local repo files are mounted at /opt/deploy inside the container."
echo "    Edit deploy.sh in VS Code or any editor — changes appear immediately inside."
echo ""

docker run -it \
    --name linuxplus-m2-session \
    --rm \
    --cap-add SYS_ADMIN \
    --volume /sys/fs/cgroup:/sys/fs/cgroup:rw \
    --cgroupns host \
    --volume "$(pwd):/opt/deploy" \
    $IMAGE_NAME /bin/bash

echo "[*] Container session ended."
echo "    Your work is saved in your local files — the container itself is temporary."