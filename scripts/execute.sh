#!/bin/bash
IMAGE_NAME="sprawl-detector"
RAILS_ENV="staging"
EXPORTS=$(aws cloudformation list-exports)
PRIVATE_SUBNET1=$(echo $EXPORTS | jq -r '.Exports[] | select(.Name == "Staging-PrivateSubnet1").Value')
PRIVATE_SUBNET2=$(echo $EXPORTS | jq -r '.Exports[] | select(.Name == "Staging-PrivateSubnet2").Value')
SG=$(echo $EXPORTS | jq -r '.Exports[] | select(.Name == "Staging-MySqlSecurityGroup").Value')
TASK_DEFINITION=$(aws ecs list-task-definitions --family $IMAGE_NAME | jq -r ".taskDefinitionArns | last")

OVERRIDES=$(jq --null-input -c \
  --arg IMAGE_NAME "$IMAGE_NAME" \
  --arg RAILS_ENV "$RAILS_ENV" \
  '{ "containerOverrides": [ {"name": $IMAGE_NAME, "command": ["bundle", "exec", "rake", "db:migrate", "db:seed"],"environment":[{ "name": "RAILS_ENV", "value": $RAILS_ENV },{"name":"USE_SECRETS","value":"true"}]} ]}')

aws ecs run-task \
  --cluster "Staging-Cluster" \
  --count 1 \
  --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNET1,$PRIVATE_SUBNET2],securityGroups=[$SG],assignPublicIp=DISABLED}" \
  --overrides $OVERRIDES \
  --task-definition $TASK_DEFINITION
