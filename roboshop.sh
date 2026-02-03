#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-05997a7119396a217"

for instance in $@
do
    aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --security-group-ids $SG_ID \
    --query 'Instances[0].InstanceId' \
    --output text
done