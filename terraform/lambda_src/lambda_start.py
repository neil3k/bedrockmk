import boto3
import os

region = 'eu-west-2'
ec2 = boto3.client('ec2', region_name=region)
instancez = os.environ.get('instances')
instances = list(instancez.split(" "))

def lambda_handler(event, context):
    ec2.start_instances(InstanceIds=instances)
    print('started your instances: ' + str(instances))