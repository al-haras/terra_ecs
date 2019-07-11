#!/bin/bash
yum install -y amazon-efs-utils
mkdir /efs
mount -t efs ${efs_id}:/ /efs
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
start ecs
