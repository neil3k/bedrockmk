"""Lambda function to backup Minecraft worlds via SSM."""

import os
import time
import boto3

INSTANCE_ID = os.environ["instance_id"]
BACKUP_BUCKET = os.environ["backup_bucket"]


def lambda_handler(event, context):
    """Trigger a world backup on the Minecraft server via SSM."""
    ssm = boto3.client("ssm")

    # Run backup command on the instance
    command = (
        f"aws s3 cp --recursive /usr/games/minecraft/worlds "
        f"s3://{BACKUP_BUCKET}/$(date +%F-%H%M)/"
    )

    response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Parameters={"commands": [command]},
        TimeoutSeconds=90,
    )

    command_id = response["Command"]["CommandId"]
    print(f"Backup command sent: {command_id}")

    # Wait for completion
    for _ in range(12):
        time.sleep(10)
        result = ssm.get_command_invocation(
            CommandId=command_id,
            InstanceId=INSTANCE_ID,
        )
        status = result["Status"]
        if status in ("Success", "Failed", "Cancelled", "TimedOut"):
            break

    print(f"Backup status: {status}")
    if status != "Success":
        print(f"Error: {result.get('StandardErrorContent', 'unknown')}")
        raise RuntimeError(f"Backup failed with status: {status}")

    return {"statusCode": 200, "body": f"Backup completed: {command_id}"}
