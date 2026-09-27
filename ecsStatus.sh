#!/usr/bin/env bash

declare -A ECS_STATUS=(
  ["ACTIVE"]="The ECS cluster is active and running."
  ["PROVISIONING"]="The ECS cluster is being provisioned."
  ["DEPROVISIONING"]="The ECS cluster is being deprovisioned."
  ["FAILED"]="The ECS cluster has failed."
  ["INACTIVE"]="The ECS cluster is inactive."
)

declare -A SERVICE_STATUS=(
  ["ACTIVE"]="The ECS service is active and running."
  ["DRAINING"]="The ECS service is draining tasks."
  ["INACTIVE"]="The ECS service is inactive."
)

declare -A TASK_STATUS=(
  ["RUNNING"]="The ECS task is running."
  ["PENDING"]="The ECS task is pending."
  ["STOPPED"]="The ECS task has stopped."
)

declare -A ecs_items_names=(
  ["cluster"]="NOT_DEFINED"
  ["service"]="NOT_DEFINED"
)

declare -A tf_items_path=(
  ["cluster"]=".ecs_cluster_name.value"
  ["service"]=".ecs_service_name.value"
  
)

## getting the terraform output in json format

terraform_output=$(terraform output -json)

declare cluster_name service_name

for item in "${!ecs_items_names[@]}"; do
  ecs_items_names[$item]=$(echo "$terraform_output" | jq -r "${tf_items_path[$item]}")
done

for item in "${!ecs_items_names[@]}"; do
  if [[ "${ecs_items_names[$item]}" == "NOT_DEFINED" ]]; then
    echo "Error: Terraform output for $item is not defined."
    exit 1
  fi
  echo "Checking status for $item: ${ecs_items_names[$item]}"
  case $item in
    "cluster")
      cluster_name=${ecs_items_names[$item]}
      cluster_status=$(aws ecs describe-clusters --clusters "${ecs_items_names[$item]}" --query "clusters[0].status" --output text)
      echo "Cluster Status: $cluster_status - ${ECS_STATUS[$cluster_status]}"
      ;;
    "service")
      service_name=${ecs_items_names[$item]}
      service_status=$(aws ecs describe-services --cluster "${ecs_items_names["cluster"]}" --services "${ecs_items_names[$item]}" --query "services[0].status" --output text)
      echo "Service Status: $service_status - ${SERVICE_STATUS[$service_status]}"

    if [[ "$service_status" == "ACTIVE" ]]; then
        desired_count=$(aws ecs describe-services --cluster "${ecs_items_names["cluster"]}" --services "${ecs_items_names[$item]}" --query "services[0].desiredCount" --output text)
        running_count=$(aws ecs describe-services --cluster "${ecs_items_names["cluster"]}" --services "${ecs_items_names[$item]}" --query "services[0].runningCount" --output text)
        pending_count=$(aws ecs describe-services --cluster "${ecs_items_names["cluster"]}" --services "${ecs_items_names[$item]}" --query "services[0].pendingCount" --output text)
        echo "Desired Count: $desired_count, Running Count: $running_count, Pending Count: $pending_count"
        echo "Fetching tasks for service: $service_name in cluster: $cluster_name"
      task_arns=$(aws ecs list-tasks --cluster "$cluster_name" --service-name "$service_name" --query "taskArns" --output text)
      if [[ -z "$task_arns" ]]; then
        echo "No tasks found for service: $service_name"
      else
        for task_arn in $task_arns; do
          task_status=$(aws ecs describe-tasks --cluster "$cluster_name" --tasks "$task_arn" --query "tasks[0].lastStatus" --output text)
          echo "Task ARN: $task_arn - Status: $task_status - ${TASK_STATUS[$task_status]}"
        done
      fi  
    fi
      
      ;; 
    *)
      echo "Unknown item: $item"
      ;;
  esac
done

# aws ecs describe-services \
#   --cluster ${ecs_items_names["cluster"]} \
#   --services ${ecs_items_names["service"]} \
#   --query 'services[0].{status: status, desired: desiredCount, running: runningCount, pending: pendingCount}'

