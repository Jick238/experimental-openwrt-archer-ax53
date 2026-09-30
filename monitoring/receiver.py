#!/usr/bin/env python3
"""Bounded UDP syslog storage on a disk filesystem, filtered to one sender."""
import logging
from logging.handlers import RotatingFileHandler
import os
from pathlib import Path
import shutil
import socket
import subprocess
import threading
import time

root = Path(os.environ.get("AX53_LOG_DIR", "/var/lib/ax53-monitor"))
root.mkdir(parents=True, exist_ok=True)
os.umask(0o077)
log = logging.getLogger("ax53")
log.setLevel(logging.INFO)
handler = RotatingFileHandler(root / "remote-syslog.log", maxBytes=8*1024*1024, backupCount=7)
handler.setFormatter(logging.Formatter("%(asctime)s %(message)s"))
log.addHandler(handler)
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((os.environ["AX53_BIND_IP"], int(os.environ.get("AX53_LOG_PORT", "5514"))))
sender = os.environ["AX53_SENDER_IP"]
def probe_router():
    while True:
        try:
            result = subprocess.run(["ping", "-n", "-c", "5", "-W", "1", sender],
                                    capture_output=True, text=True, timeout=12)
            summary = " ".join(line for line in result.stdout.splitlines()
                               if "packet loss" in line or "min/avg" in line)
            if shutil.disk_usage(root).free >= 256*1024*1024:
                log.info("host-probe router rc=%s %s", result.returncode, summary or "no-summary")
        except (OSError, subprocess.TimeoutExpired) as exc:
            if shutil.disk_usage(root).free >= 256*1024*1024:
                log.warning("host-probe error=%s", type(exc).__name__)
        time.sleep(60)
threading.Thread(target=probe_router, daemon=True).start()
while True:
    data, peer = sock.recvfrom(16384)
    if peer[0] != sender:
        continue
    # Resume automatically once disk free space recovers; no router actions.
    if shutil.disk_usage(root).free < 256*1024*1024:
        continue
    log.info("%s", data.decode("utf-8", "replace").replace("\n", " ").replace("\r", " "))
