#!/bin/bash
terraform init
terraform apply -auto-approve
wireguard_client_config=$(terraform output -raw client_config 2>&1)
if [ $? != 0 ]; then
    echo "Terraform Wireguard Client Config Output Failed, check your Terraform Configuration"
    exit 1
fi
sudo mkdir -p /etc/wireguard
sudo sh -c "echo '$wireguard_client_config' > /etc/wireguard/wg0.conf"

# Get the instance ID of the EC2 instance
ec2_instance_id=$(terraform output -raw instance_id 2>&1)
if [ $? != 0 ]; then
    echo "Terraform EC2 Instance ID Output Failed, check your Terraform Configuration"
    exit 1
fi

# Get the region of the EC2 instance
ec2_region=$(terraform output -raw region 2>&1)
if [ $? != 0 ]; then
    echo "Terraform EC2 Region Output Failed, check your Terraform Configuration"
    exit 1
fi

# Wait for the instance to reach the running state
echo "Waiting for EC2 instance to reach the running state..."
aws ec2 wait instance-status-ok --instance-ids "$ec2_instance_id"

# Check if Wireguard Server is running before starting the client
while ! aws ssm send-command \
        --document-name "AWS-RunShellScript" \
        --instance-ids "$ec2_instance_id" \
        --parameters commands="sudo systemctl is-active --quiet wg-quick@wg0.service" \
        --query "CommandInvocations[0].CommandPlugins[0].Output" \
        --output text \
        --region "$ec2_region" | grep -q "None"; do
    echo "Waiting for Wireguard Server to start..."
    sleep 5
done

sudo systemctl start wg-quick@wg0.service
sudo systemctl status wg-quick@wg0.service
