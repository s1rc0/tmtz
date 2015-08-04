#!/bin/bash

########=======================================Config====================================##########
### Launch Configuration Options
launch_configuration_name=tmtz
#image_id=ami-81d092b1                  # CentOS 6 x64 HVM
image_id=ami-c7d092f7                   # CentOS 7 x64 HVM
key_name=tmtz
security_groups=tmtz
instance_type=t2.micro

### ELB Options
load_balancer_name=tmtz
lb_port=80
instance_port=80
avail_zones_elb="us-west-2a"
lb_protocol="HTTP"
instance_protocol="HTTP"


### AutoScaling Options
asg_availability_zones="us-west-2a"
asg_health_check_type=EC2
asg_health_check_grace_period=120
asg_min_size=1
asg_max_size=2

########=======================================End_Config====================================##########

### Creates LaunchConfiguration and ELB (Return ELB URL)

# Create ELB
dns_hostname_elb=`aws elb create-load-balancer --load-balancer-name ${load_balancer_name} --listeners "Protocol=${lb_protocol},LoadBalancerPort=${lb_port},InstanceProtocol=${instance_protocol},InstancePort=${instance_port}" --availability-zones=${avail_zones_elb}`

# Create LaunchConfiguration
aws autoscaling create-launch-configuration --launch-configuration-name ${launch_configuration_name} --image-id ${image_id} --key-name ${key_name} --security-groups ${security_groups} --instance-type ${instance_type} --user-data file://tmtz-userdata.txt

# Create AutoScalingGroup
aws autoscaling create-auto-scaling-group --auto-scaling-group-name tmtz --launch-configuration-name ${launch_configuration_name} --load-balancer-names ${load_balancer_name} --health-check-type ${asg_health_check_type} --health-check-grace-period ${asg_health_check_grace_period} --min-size ${asg_min_size} --max-size ${asg_max_size} --availability-zones ${asg_availability_zones}

echo "WP will be available on:  http://${dns_hostname_elb}/"
