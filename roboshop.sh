#!/bin/bash

SG_ID="sg-0cecc7f37156227f4"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z004782564HOFLM6URBO"
DOMAIN_NAME="kcdevops.online"

if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: AWS CLI is not installed or not in PATH."
    echo "Install AWS CLI and retry: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

for instance in "$@"
do
    INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
        IP=$( 
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text 
        )
        RECORD_NAME="$DOMAIN_NAME" # kcdevops.online
    else
        IP=$( 
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text 
        )
        RECORD_NAME="$instance.$DOMAIN_NAME" # component.kcdevops.online
    fi

    echo "IP Address of $instance is $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch '{
        "Comment": "Updating DNS record",
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$RECORD_NAME'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [
                        {
                            "Value": "'$IP'"
                        }
                    ]
                }
            }
        ]
    }'

    echo "record updated for $instance"

done