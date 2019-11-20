import boto3 
import os

def lambda_handler(event, context): 
 
   accountname = boto3.client('iam').list_account_aliases()['AccountAliases'][0]
   topicarn = os.environ["NotifyTopicArn"]
   sync_tag_keys = os.environ["SyncTagKeys"] 
   instancename = '' 
   
   ec2_resource = boto3.resource('ec2') 
   ec2_client = boto3.client('ec2')
   sns_client = boto3.client('sns') 
 
   try: 
 
	   eventname = event['detail-type'] 
	   detail = event['detail'] 
 
	   if eventname == 'Tag Change on Resource': 
			 
		   if detail['service'] == 'ec2' and detail['resource-type'] == 'instance': 
 
			   changedtags = detail['changed-tag-keys'] 
			   resources = event['resources'][0].split('/') 
			   instanceid = resources[len(resources) - 1] 
				 
			   synctags = [t for t in changedtags or [] if t in sync_tag_keys] 
			   if not synctags: 
				   print("info: no matching changed tags") 
				   return 
				 
			   instance = ec2_resource.Instance(instanceid) 
 
			   tags = [t for t in instance.tags or [] if t['Key'] in sync_tag_keys] 
			   if not tags: 
				   print("info: no matching instance tags") 
				   return 
 
			   for vol in instance.volumes.all(): 
				   vol.create_tags(Tags=tags) 
				   snapshots = ec2_client.describe_snapshots(Filters=[{'Name':'volume-id','Values':[vol.id]}])['Snapshots']
				   for snap in snapshots:
				     snapshot = ec2_resource.Snapshot(snap['SnapshotId']) 
				     snapshot.create_tags(Tags=tags)

			   for eni in instance.network_interfaces: 
				   eni.create_tags(Tags=tags) 
				   
			   addresses = ec2_client.describe_addresses(Filters=[{'Name':'instance-id','Values':[instanceid]}])['Addresses']
			   for addr in addresses:
			     address = ec2_resource.VpcAddress(addr['AllocationId'])
			     ec2_client.create_tags(Resources=[addr['AllocationId']],Tags=tags)

			   for tag in instance.tags: 
				   if 'Name' in tag['Key']: 
					   instancename = tag['Value'] 
  
			   print('success: updated child resource tags for instance ' + instancename)
			   
			   subject = 'Tags Update Event - ' + accountname + ' - ' + instancename 
			   message = 'Instance Name: ' + instancename + '\r\rTags:\r' + str(instance.tags) + '\r\rEvent Detail:\r' + str(event) 
			 
			   response = sns_client.publish( 
				   TopicArn=topicarn,Message=message,Subject=subject 
			   ) 
			 
	   return True 
   except Exception as e: 
	   print(e) 
	   return False    			  