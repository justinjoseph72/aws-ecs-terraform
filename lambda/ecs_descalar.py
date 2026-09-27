import boto3
import logging
import json

# Create an ECS client
ecs_client = boto3.client('ecs')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

    clusterName = event.get('clusterName') if isinstance(event, dict) else None

    if not clusterName:
        logger.error("No cluster name provided in the event.")
        return {
            'statusCode': 400,
            'body': 'No cluster name provided in the event.'
        }

    logger.info(f"Received request to scale down all services in cluster {clusterName} to 0 tasks.")

    try:
        clusterResponse = ecs_client.describe_clusters(clusters=[clusterName])
        if not clusterResponse['clusters']:
            logger.error(f"Cluster {clusterName} does not exist.")
            return {
                'statusCode': 200,
                'body': f'Cluster {clusterName} does not exist. No scaling action taken.'
            }
        clusterStatus = clusterResponse['clusters'][0]['status']

        if clusterStatus != 'ACTIVE':
            logger.error(f"Cluster {clusterName} is not active. Current status: {clusterStatus}")
            return {
                'statusCode': 200,
                'body': f'Cluster {clusterName} is not active. Current status: {clusterStatus}. No scaling action taken.'
            }
    except Exception as e:
        logger.error(f"Error checking cluster {clusterName}: {str(e)}")
        return {
            'statusCode': 500,
            'body': f'Error checking cluster {clusterName}: {str(e)}'
        }   

    try:
        args = {'cluster': clusterName, 'maxResults': 10}
        servicesResponse = ecs_client.list_services(**args)
    except Exception as e:
        logger.error(f"Error listing services in cluster {clusterName}: {str(e)}")
        return {
            'statusCode': 500,
            'body': f'Error listing services in cluster {clusterName}: {str(e)}'
        }

    servicesScaledDown = []
    failedServices = []

    while True:
        try:
            serviceArns = servicesResponse['serviceArns']
            nextToken = servicesResponse.get('nextToken')    
            serviceListDetails = ecs_client.describe_services(cluster=clusterName, services=[serviceArns])
        except Exception as e:
            logger.error(f"Error describing services in cluster {clusterName}: {str(e)}")
            return {
                'statusCode': 500,
                'body': f'Error describing services in cluster {clusterName}: {str(e)}'
            }
        # filter and get the services that are ACTIVE
        activeServices = [service for service in serviceListDetails['services'] if service['status'] == 'ACTIVE']
        for service in activeServices:
            serviceName = service['serviceName']
            logger.info(f"Scaling down service {serviceName} in cluster {clusterName} to 0 tasks.")
            
            # Update the desired count to 0 to scale down the service
            try:
                response = ecs_client.update_service(
                    cluster=clusterName,
                    service=serviceName,
                    desiredCount=0
                )
                servicesScaledDown.append(serviceName)
                logger.info(f"Successfully scaled down service {serviceName} in cluster {clusterName} to 0 tasks.")
            except Exception as e:
                logger.error(f"Failed to scale down service {serviceName} in cluster {clusterName}. Error: {str(e)}")
                failedServices.append(serviceName)

        if nextToken == 'null' or nextToken is None:
            break    
        else:
            logger.info(f"Fetching next page of services for cluster {clusterName} with nextToken: {nextToken}")
            args = {'cluster': clusterName, 'nextToken': nextToken, 'maxResults': 10}
            servicesResponse = ecs_client.list_services(**args)

    response_body = {
        'servicesScaledDown': servicesScaledDown,
        'failedServices': failedServices
    }


    return {
        'statusCode': 200,
        'body': json.dumps(response_body)
    }
    
