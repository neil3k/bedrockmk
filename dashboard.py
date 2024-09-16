import streamlit as st
import boto3

ec2 = boto3.resource('ec2')

st.title("AWS Auto-Scaling Web App Dashboard")

st.header("EC2 Instances")

for instance in ec2.instances.all():
    st.write(f"Instance ID: {instance.id}")
    st.write(f"State: {instance.state['Name']}")
    st.write("---")