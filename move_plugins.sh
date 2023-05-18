# Get containerID by name
CONTAINER1=$(docker ps --format "table {{.Names}}\t{{.ID}}" | tr -s ' ' | grep ^p | grep peer0.org1.example.com | awk '{print $2}')
CONTAINER2=$(docker ps --format "table {{.Names}}\t{{.ID}}" | tr -s ' ' | grep ^p | grep peer0.org2.example.com | awk '{print $2}')

# Create plugins folder on containers
docker exec -it "$CONTAINER1" sh -c "mkdir -p /etc/hyperledger/fabric/plugins"
docker exec -it "$CONTAINER2" sh -c "mkdir -p /etc/hyperledger/fabric/plugins"

# Copy plugins to containers
docker cp /home/alfredo/go/src/github.com/alfredom/fabric-samples/test-network-3-orgs/custom_validation/sample_validation.so "$CONTAINER1":/etc/hyperledger/fabric/plugins
docker cp /home/alfredo/go/src/github.com/alfredom/fabric-samples/test-network-3-orgs/custom_validation/sample_validation.so "$CONTAINER2":/etc/hyperledger/fabric/plugins

docker cp /home/alfredo/go/src/github.com/alfredom/fabric-samples/test-network-3-orgs/custom_validation/timebased_validation.so "$CONTAINER2":/etc/hyperledger/fabric/plugins
docker cp /home/alfredo/go/src/github.com/alfredom/fabric-samples/test-network-3-orgs/custom_validation/timebased_validation.so "$CONTAINER1":/etc/hyperledger/fabric/plugins

# Access plugin location on container
docker exec -it "$CONTAINER1" sh -c "cd /etc/hyperledger/fabric/plugins && ls"
docker exec -it "$CONTAINER2" sh -c "cd /etc/hyperledger/fabric/plugins && ls"

# TODO: Modify /etc/hyperledger/peercfg/core.yaml to include plugins under handlers.validators
#docker exec -it "$CONTAINER1" sh -c "sed -i 's/validators:/validators:\n          custom: sample_validation_mesl_alpine.so\n      library: /etc/hyperledger/fabric/plugins/sample_validation_mesl_alpine.so\n       custom2: timebased_validation.so\n      library: /etc/hyperledger/fabric/plugins.so/g' /etc/hyperledger/peercfg/core.yaml"

# Restart containers
docker restart "$CONTAINER1"
docker restart "$CONTAINER2"
