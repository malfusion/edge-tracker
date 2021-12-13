aws ec2 create-key-pair --key-name <Keyname> --query 'KeyMaterial' --output text > <Keyname>.pem
export REGION="us-west-2"
export WL_ZONE="us-west-2-wl1-sfo-wlz-1"
export NBG="us-west-2-wl1-sfo-wlz-1"
export API_IMAGE_ID="ami-09889d8d54f9e0a0e"
export BACKEND_IMAGE_ID="ami-09889d8d54f9e0a0e"
export KEY_NAME="<Keyname>"

export VPC_ID=$(aws ec2 --region $REGION \
--output text \
create-vpc \
--cidr-block 10.0.0.0/16 \
--query 'Vpc.VpcId') \
&& echo '\nVPC_ID='$VPC_ID

export IGW_ID=$(aws ec2 --region $REGION \
--output text \
create-internet-gateway \
--query 'InternetGateway.InternetGatewayId') \
&& echo '\nIGW_ID='$IGW_ID

aws ec2 --region $REGION \
attach-internet-gateway \
--vpc-id $VPC_ID \
--internet-gateway-id $IGW_ID


export CAGW_ID=$(aws ec2 --region $REGION \
--output text \
create-carrier-gateway \
--vpc-id $VPC_ID \
--query 'CarrierGateway.CarrierGatewayId') \
&& echo '\nCAGW_ID='$CAGW_ID

// ----------------------------------------------------------

export BACKEND_SG_ID=$(aws ec2 --region $REGION \
--output text \
create-security-group \
--group-name backend-sg \
--description "Security group for backend host" \
--vpc-id $VPC_ID \
--query 'GroupId') \
&& echo '\nBACKEND_SG_ID='$BACKEND_SG_ID

aws ec2 --region $REGION \
authorize-security-group-ingress \
--group-id $BACKEND_SG_ID \
--protocol tcp \
--port 22 \
--cidr $(curl https://checkip.amazonaws.com)/32

aws ec2 --region $REGION \
authorize-security-group-ingress \
--group-id $BACKEND_SG_ID \
--protocol tcp \
--port 80 \
--cidr 0.0.0.0/0


export API_SG_ID=$(aws ec2 --region $REGION \
--output text \
create-security-group \
--group-name api-sg \
--description "Security group for API host" \
--vpc-id $VPC_ID \
--query 'GroupId') \
&& echo '\nAPI_SG_ID='$API_SG_ID

aws ec2 --region $REGION \
authorize-security-group-ingress \
--group-id $API_SG_ID \
--protocol tcp \
--port 22 \
--source-group $BACKEND_SG_ID

aws ec2 --region $REGION \
authorize-security-group-ingress \
--group-id $API_SG_ID \
--protocol tcp \
--port 5000 \
--cidr 0.0.0.0/0


// ------------------------------------------


export WL_SUBNET_ID=$(aws ec2 --region $REGION \
--output text \
create-subnet \
--cidr-block 10.0.0.0/24 \
--availability-zone $WL_ZONE \
--vpc-id $VPC_ID \
--query 'Subnet.SubnetId') \
&& echo '\nWL_SUBNET_ID='$WL_SUBNET_ID

export WL_RT_ID=$(aws ec2 --region $REGION \
--output text \
create-route-table \
--vpc-id $VPC_ID \
--query 'RouteTable.RouteTableId') \
&& echo '\nWL_RT_ID='$WL_RT_ID


aws ec2 --region $REGION \
associate-route-table \
--route-table-id $WL_RT_ID \
--subnet-id $WL_SUBNET_ID

aws ec2 --region $REGION create-route \
--route-table-id $WL_RT_ID \
--destination-cidr-block 0.0.0.0/0 \
--carrier-gateway-id $CAGW_ID

BACKEND_SUBNET_ID=$(aws ec2 --region $REGION \
--output text \
create-subnet \
--cidr-block 10.0.1.0/24 \
--vpc-id $VPC_ID \
--query 'Subnet.SubnetId') \
&& echo '\nBACKEND_SUBNET_ID='$BACKEND_SUBNET_ID


export BACKEND_RT_ID=$(aws ec2 --region $REGION \
--output text \
create-route-table \
--vpc-id $VPC_ID \
--query 'RouteTable.RouteTableId') \
&& echo '\nBACKEND_RT_ID='$BACKEND_RT_ID

aws ec2 --region $REGION \
create-route \
--route-table-id $BACKEND_RT_ID \
--destination-cidr-block 0.0.0.0/0 \
--gateway-id $IGW_ID

aws ec2 --region $REGION \
associate-route-table \
--subnet-id $BACKEND_SUBNET_ID \
--route-table-id $BACKEND_RT_ID

aws ec2 --region $REGION \
modify-subnet-attribute \
--subnet-id $BACKEND_SUBNET_ID \
--map-public-ip-on-launch

//--------------------


export API_CIP_ALLOC_ID=$(aws ec2 --region $REGION \
--output text \
allocate-address \
--domain vpc \
--network-border-group $NBG \
--query 'AllocationId') \
&& echo '\nAPI_CIP_ALLOC_ID='$API_CIP_ALLOC_ID



export API_ENI_ID=$(aws ec2 --region $REGION \
--output text \
create-network-interface \
--subnet-id $WL_SUBNET_ID \
--groups $API_SG_ID \
--query 'NetworkInterface.NetworkInterfaceId') \
&& echo '\nAPI_ENI_ID='$API_ENI_ID

aws ec2 --region $REGION associate-address \
--allocation-id $API_CIP_ALLOC_ID \
--network-interface-id $API_ENI_ID


///------------------------------


aws ec2 --region $REGION \
run-instances \
--instance-type t3.medium \
--network-interface '[{"DeviceIndex":0,"NetworkInterfaceId":"'$API_ENI_ID'"}]' \
--image-id $API_IMAGE_ID \
--key-name $KEY_NAME

aws ec2 --region $REGION run-instances \
--instance-type t3.medium \
--associate-public-ip-address \
--subnet-id $BACKEND_SUBNET_ID \
--image-id $BACKEND_IMAGE_ID \
--security-group-ids $BACKEND_SG_ID \
--key-name $KEY_NAME


