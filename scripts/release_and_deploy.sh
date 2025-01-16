#!/bin/bash

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "Failed to retrieve AWS account ID. Ensure AWS credentials are properly configured."
    exit 1
fi

if [ -z "$OPENAI_API_KEY" ]; then
    echo "Please setup your OPENAI_API_KEY"
    exit 1
fi

# Constants

cluster_name="ace-healthcare-dev-cluster"
service_name="data-copilot"
task_family="data-copilot"
DOCKER_IMAGE_NAME="transformgovsg/data-copilot"
REPOSITORY_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/data-copilot"
TARGET_IMAGE_CONTAINER_NAME=streamlit

# Fetch tags from remote
git fetch --tags

# Get the latest tag from Git
latest_tag=$(git describe --tags `git rev-list --tags --max-count=1`)

# If no tag found, start from 0.0.0
if [ -z "$latest_tag" ]; then
  latest_tag="0.0.0"
fi

# Break the tag into major, minor and patch versions
IFS='.' read -ra ADDR <<< "$latest_tag"
major="${ADDR[0]}"
minor="${ADDR[1]}"
patch="${ADDR[2]}"

# Increment the patch version
new_patch=$((patch + 1))

# Create new tag
new_tag="$major.$minor.$new_patch"

# Output new tag
echo "New tag: $new_tag"

git_log=$(git log --oneline --abbrev-commit $latest_tag..main)
formatted_log=$(echo "$git_log" | sed -E 's/^[a-f0-9]+ (\(tag: v[\d.]+\))?//')

echo $formatted_log | ./scripts/changelogs.py

git add chainlit.md
git commit -S -m "chore: update changelogs for $new_tag [deploy script]"
git push

# Create and push the new tag to remote
git tag $new_tag
git push origin $new_tag

# ================
# DEPLOY ECR Image
# ================

# Build Docker image
docker buildx build -t $DOCKER_IMAGE_NAME .

# Tag the Docker image with the new version
docker tag $DOCKER_IMAGE_NAME:latest $REPOSITORY_URL:$new_tag

# Login to AWS ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REPOSITORY_URL

# Push the Docker image
docker push $REPOSITORY_URL:$new_tag

# =======================================
# DEPLOY ECS Task Definition and Service
# =======================================

# Fetch the current task definition JSON
task_def_json=$(aws ecs describe-task-definition --task-definition $task_family)

# Extract values needed for the new task definition
execution_role_arn=$(echo $task_def_json | jq -r '.taskDefinition.executionRoleArn')
task_role_arn=$(echo $task_def_json | jq -r '.taskDefinition.taskRoleArn')
requires_compatibilities=$(echo $task_def_json | jq -r '.taskDefinition.requiresCompatibilities | @csv' | sed 's/"//g')
cpu=$(echo $task_def_json | jq -r '.taskDefinition.cpu')
memory=$(echo $task_def_json | jq -r '.taskDefinition.memory')
network_mode=$(echo $task_def_json | jq -r '.taskDefinition.networkMode')
runtime_platform_os=$(echo $task_def_json | jq -r '.taskDefinition.runtimePlatform.operatingSystemFamily')
runtime_platform_cpu_arch=$(echo $task_def_json | jq -r '.taskDefinition.runtimePlatform.cpuArchitecture')
container_definitions=$(echo $task_def_json | jq --arg IMAGE "$REPOSITORY_URL:$new_tag" --arg TARGET_IMAGE_CONTAINER_NAME "$TARGET_IMAGE_CONTAINER_NAME" '.taskDefinition.containerDefinitions | map(.image = if .name == $TARGET_IMAGE_CONTAINER_NAME then $IMAGE else .image end)')

# Create a new task definition revision with the new image
new_task_definition=$(aws ecs register-task-definition \
    --family $task_family \
    --execution-role-arn $execution_role_arn \
    --task-role-arn $task_role_arn \
    --requires-compatibilities $requires_compatibilities \
    --cpu $cpu \
    --memory $memory \
    --network-mode $network_mode \
    --runtime-platform operatingSystemFamily=$runtime_platform_os,cpuArchitecture=$runtime_platform_cpu_arch \
    --container-definitions "$container_definitions" \
    --query 'taskDefinition.taskDefinitionArn' --output text)

echo "New task definition created: $new_task_definition"

# Update the ECS service to use the new task definition
aws ecs update-service \
  --cluster $cluster_name \
  --service $service_name \
  --task-definition $new_task_definition \
  --force-new-deployment

echo "Service updated to use new task definition"
