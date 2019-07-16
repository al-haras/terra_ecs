#!/bin/bash
yum install -y amazon-efs-utils
mkdir /efs
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
start ecs
sleep 60s
mount -t efs ${efs_id}:/ /efs
