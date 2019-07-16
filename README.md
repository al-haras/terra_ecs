## Work in Progress

This is just a space to work on a project which will deploy Minecraft into ECS containers using Terraform.

## Docker:
Dockerfile is included just for reference. Docker image is at ```alharas/minecraft-server-nfs:1.0```

## Terraform:
Complete:
- EC2-ECS Instance with bootstrap (.tpl) - Bootstrap has to wait for DNS apply to VPC for EFS currently to get the correct EFS ID to mount. Attempted to set depends on module.efs.id but it is still not seeing right away. It is currently set to wait 60 seconds and working as EFS may take up to 90 seconds for volume to be mountable.
- SSH Keys
- ECS Cluster Creation
- EFS Volume Creation
- SGs - EFS (Ingress 2049, Egress 0.0.0.0/0 - May remove or rework), Minecraft (Ingress 25565, 22 (From only your public IP), Egress 0.0.0.0/0)
- Working Docker image with script installed to check for server on EFS volume and if it doesnt exist to download before running.
- Networking for Public and Private Subnets - NAT gateways likely need to be altered once services are active

To Do:
- ECS-Service Deployment using run-server.json Task Definition (Associate Tasks with NLB with Port 25565 pointing to target group). These are going to be launched using awsvpc and in one of the private subnets with route to NAT gateway. Additional SG may be created for just 25565 for the NLB and containers. May require making module.
- ecsInstance role to register EC2 instance with Cluster - Policy ARN: arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role
- Overall streamlining/splitting main.tf into other tf files.
- Add more notes overall to code.
