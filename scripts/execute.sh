#!/bin/bash
EXPORTS=$(aws cloudformation list-exports)
PRIVATE_SUBNET1=$(echo $EXPORTS | jq -r '.Exports[] | select(.Name == "Staging-PrivateSubnet1").Value')
PRIVATE_SUBNET2=$(echo $EXPORTS | jq -r '.Exports[] | select(.Name == "Staging-PrivateSubnet2").Value')
SG=$(echo $EXPORTS | jq -r '.Exports[] | select(.Name == "Staging-MySqlSecurityGroup").Value')
TASK_DEFINITION=$(aws ecs list-task-definitions --family sprawl-detector | jq -r ".taskDefinitionArns | last")

aws ecs run-task \
  --cluster Staging-Cluster \
  --count 1 \
  --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNET1,$PRIVATE_SUBNET2],securityGroups=[$SG],assignPublicIp=DISABLED}" \
  --overrides '{ "containerOverrides": [ {"name": "sprawl-detector", "command": ["bundle", "exec", "rake", "db:migrate"],"environment":[{ "name": "RAILS_ENV", "value": "staging"},{"name":"USE_SECRETS","value":"true"}]} ]}'\
  --task-definition "$TASK_DEFINITION"
