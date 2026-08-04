# Minecraft Bedrock Dedicated Server

Terraform-managed Minecraft Bedrock Edition dedicated server running on AWS (eu-west-2).

## Architecture

- **EC2** (t3.small) — Runs the Bedrock Dedicated Server on Ubuntu
- **Elastic IP** — Static public IP for consistent DNS
- **Route 53** — DNS at `pattersonminecraft.com`
- **EventBridge Scheduler** — Auto start/stop (15:00–20:00 UTC daily)
- **Lambda** — Start/stop functions triggered by the scheduler
- **S3** — World backup storage (`bedrock-minecraft-backups`)
- **SNS** — SMS notifications
- **SSM** — Instance management without SSH

## Connecting

- **Address:** `pattersonminecraft.com`
- **Port:** `19132` (default Bedrock port)
- **Server hours:** 15:00–20:00 UTC (configurable in `eventbridge.tf`)

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) (>= 1.0)
- AWS CLI configured with appropriate credentials
- An existing VPC and subnet in eu-west-2
- A Route 53 hosted zone for your domain
- An EC2 key pair named `minecraft`

## Deployment

```bash
cd terraform

# Create your tfvars file (see terraform.tfvars.example)
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your phone numbers

terraform init
terraform plan
terraform apply
```

## Upgrading the Server

SSH into the instance and run:

```bash
sudo /usr/games/upgrade.sh 1.26.36.1
```

Or interactively (it will prompt for version):

```bash
sudo /usr/games/upgrade.sh
```

This will:
1. Stop the server
2. Backup worlds to S3
3. Download and install the new version
4. Restart the server

Find the latest version at: https://www.minecraft.net/en-us/download/server/bedrock

## File Structure

```
terraform/
├── compute.tf          # EC2 instance, security group, EIP
├── data.tf             # VPC/subnet data sources
├── eventbridge.tf      # Auto start/stop schedules
├── iam.tf              # IAM roles for Lambda, scheduler, SSM
├── lambda.tf           # Start/stop Lambda functions
├── minecraft.sh        # EC2 user_data bootstrap script
├── output.tf           # Terraform outputs (IP, instance ID)
├── providers.tf        # AWS provider & S3 backend config
├── r53.tf              # Route 53 DNS records
├── s3.tf               # Backup bucket
├── sns.tf              # SMS notifications
├── upgrade.sh          # Server upgrade script (deployed to instance)
└── variables.tf        # Input variables
```

## Security Groups

| Port  | Protocol | Purpose          |
|-------|----------|------------------|
| 19132 | UDP      | Minecraft Bedrock |
| 19133 | UDP      | Minecraft Bedrock |
| 22    | TCP      | SSH               |

## Notes

- The server runs as a systemd service (`minecraft.service`) with auto-restart on failure
- Worlds are preserved during upgrades — only binaries and resource packs are overwritten
- The server must match your client version exactly or you won't be able to connect
- If the allowlist is enabled, gamertags must be added to `/usr/games/minecraft/allowlist.json`
