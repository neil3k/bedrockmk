"""Lambda function to auto-upgrade Minecraft Bedrock server if a new version is available."""

import json
import os
import re
import time
import urllib.request

import boto3

INSTANCE_ID = os.environ["instance_id"]
INSTALL_DIR = "/usr/games/minecraft"
DOWNLOAD_DIR = "/usr/games/minecraft_downloads"
BACKUP_BUCKET = os.environ["backup_bucket"]

# GitHub-hosted JSON tracking Bedrock server versions (updated daily)
VERSION_API_URL = "https://raw.githubusercontent.com/kittizz/bedrock-server-downloads/main/bedrock-server-downloads.json"
# Direct download page (fallback - works when rendered)
DOWNLOAD_PAGE_URL = "https://www.minecraft.net/bedrockdedicatedserver/bin-linux/"


def get_latest_version():
    """Fetch the latest stable Linux server version. Tries multiple sources."""
    # Try the direct download URL pattern first (HEAD request to check latest known)
    # Try the GitHub tracking API
    try:
        req = urllib.request.Request(VERSION_API_URL, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))

        releases = data.get("release", {})
        if releases:
            def version_sort_key(v):
                parts = v.split(".")
                return tuple(int(p) for p in parts)

            latest_key = sorted(releases.keys(), key=version_sort_key)[-1]
            linux_info = releases[latest_key].get("linux", {})
            url = linux_info.get("url", "")

            if url:
                match = re.search(r"bedrock-server-(\d+\.\d+\.\d+\.\d+)\.zip", url)
                version = match.group(1) if match else latest_key
                return version, url
    except Exception as e:
        print(f"GitHub API failed: {e}, trying known URL pattern")

    # Fallback: try incrementing from a known recent version
    # Check if a newer version exists by doing a HEAD request
    known_versions = [
        "1.26.40.8", "1.26.36.1", "1.26.30.5"
    ]
    for version in known_versions:
        url = f"https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-{version}.zip"
        try:
            req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=10) as resp:
                if resp.status == 200:
                    return version, url
        except Exception:
            continue

    raise RuntimeError("Could not determine latest server version from any source")


def get_current_version(ssm):
    """Get the currently installed version from the server."""
    response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Parameters={
            "commands": [
                f"grep -oP 'Version\\s+\\K[\\d.]+' {INSTALL_DIR}/release-notes.txt 2>/dev/null | head -1 || echo 'unknown'"
            ]
        },
        TimeoutSeconds=30,
    )
    command_id = response["Command"]["CommandId"]

    for _ in range(6):
        time.sleep(5)
        result = ssm.get_command_invocation(CommandId=command_id, InstanceId=INSTANCE_ID)
        if result["Status"] in ("Success", "Failed", "Cancelled", "TimedOut"):
            break

    if result["Status"] == "Success":
        return result["StandardOutputContent"].strip()
    return "unknown"


def run_upgrade(ssm, version, download_url):
    """Run the upgrade script on the instance via SSM."""
    commands = [
        "set -e",
        f"systemctl stop minecraft.service || true",
        "sleep 5",
        f"rm -rf {DOWNLOAD_DIR}/*",
        f"aws s3 cp --recursive {INSTALL_DIR}/worlds s3://{BACKUP_BUCKET}/pre-upgrade-$(date +%F-%H%M)/",
        f"cd {DOWNLOAD_DIR}",
        f"wget -q {download_url}",
        f"unzip -o bedrock-server-{version}.zip",
        f"cp bedrock_server {INSTALL_DIR}/",
        f"cp bedrock_server_symbols.debug {INSTALL_DIR}/ 2>/dev/null || true",
        f"cp -r resource_packs {INSTALL_DIR}/ 2>/dev/null || true",
        f"cp -r definitions {INSTALL_DIR}/ 2>/dev/null || true",
        "systemctl start minecraft.service",
    ]

    response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Parameters={"commands": commands, "workingDirectory": [DOWNLOAD_DIR]},
        TimeoutSeconds=180,
    )
    command_id = response["Command"]["CommandId"]
    print(f"Upgrade command sent: {command_id}")

    for _ in range(18):
        time.sleep(10)
        result = ssm.get_command_invocation(CommandId=command_id, InstanceId=INSTANCE_ID)
        if result["Status"] in ("Success", "Failed", "Cancelled", "TimedOut"):
            break

    print(f"Upgrade status: {result['Status']}")
    if result["Status"] != "Success":
        print(f"stderr: {result.get('StandardErrorContent', '')}")
        raise RuntimeError(f"Upgrade failed: {result['Status']}")

    return result["Status"]


def lambda_handler(event, context):
    """Check for new version and upgrade if available."""
    ssm = boto3.client("ssm")

    latest, download_url = get_latest_version()
    current = get_current_version(ssm)

    print(f"Current version: {current}, Latest version: {latest}")

    if current == latest:
        print("Already up to date, nothing to do.")
        return {"statusCode": 200, "body": f"Already on {current}"}

    print(f"Upgrading from {current} to {latest}...")
    run_upgrade(ssm, latest, download_url)

    return {"statusCode": 200, "body": f"Upgraded from {current} to {latest}"}
