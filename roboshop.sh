#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-05997a7119396a217"
DOMAIN_NAME="repaka.online"
ZONE_ID="Z0043659BDU9NVUF44DT"

for instance in $@
do
        INSTANCE_ID=$( aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --security-group-ids $SG_ID \
        --query 'Instances[0].InstanceId' \
        --output text )

    if [ $instance == "frontend" ]; then
        IP=$( aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[].Instances[].PublicIpAddress' \
        --output text )
        RECORD_NAME=$DOMAIN_NAME # repaka.online
    else 
        IP=$( aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[].Instances[].PrivateIpAddress' \
        --output text )
        RECORD_NAME=$instance.$DOMAIN_NAME # mongo.repaka.online
    fi
        echo "IP address : $IP"
        aws route53 change-resource-record-sets \
            --hosted-zone-id $ZONE_ID \
            --change-batch '
            {
                "Comment": "Updating record",
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
            }
            '
    echo "record updated for $instance"
done