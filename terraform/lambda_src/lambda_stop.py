import boto3
import os

region = 'eu-west-2'
ec2 = boto3.client('ec2', region_name=region)
instancez = os.environ.get('instances')
instances = list(instancez.split(" "))

def lambda_handler(event, context):
    ec2.stop_instances(InstanceIds=instances)
    print('stopped your instances: ' + str(instances))