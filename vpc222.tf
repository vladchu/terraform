provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  region = "eu-west-3"
  alias  = "France"
}

provider "aws" {
  region = "eu-west-2"
  alias  = "England"
}
# В цьому коді чорт ногу зломить, але він працює

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++_ German _++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Create VPC
resource "aws_vpc" "vpc-ger" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "German_VPC"
  }
}

# Create Internet Gateway and Attach it to VPC
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc-ger.id
  tags = {
    Name = "German_internet_gateway"
  }
}

# Create Public Subnet
resource "aws_subnet" "public-subnet-german" {
  vpc_id                  = aws_vpc.vpc-ger.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-german"
  }
}

# Create Route Table and Add Public Route
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc-ger.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
  tags = {
    Name = "German Route Table"
  }
}
# Add route table
resource "aws_route" "ger-to-fra" {
  route_table_id            = aws_route_table.public-route-table.id
  destination_cidr_block    = "172.16.1.0/24"
  vpc_peering_connection_id = aws_vpc_peering_connection.ger-to-eng.id
}
resource "aws_route" "ger-to-eng" {
  route_table_id            = aws_route_table.public-route-table.id
  destination_cidr_block    = "192.168.1.0/24"
  vpc_peering_connection_id = aws_vpc_peering_connection.fra-to-ger.id
}

# Associate Public Subnet to "Public Route Table"
resource "aws_route_table_association" "public-subnet-german-route-table-association" {
  subnet_id      = aws_subnet.public-subnet-german.id
  route_table_id = aws_route_table.public-route-table.id
}

# Perring install
resource "aws_vpc_peering_connection" "ger-to-eng" {
  provider      = aws.England
  peer_owner_id = "561103389959"
  peer_vpc_id   = aws_vpc.vpc-ger.id
  vpc_id        = aws_vpc.vpc-eng.id
  peer_region   = "eu-central-1"
  tags = {
    Side = "Requester"
  }
}
resource "aws_vpc_peering_connection_accepter" "accept-eng2" {
  vpc_peering_connection_id = aws_vpc_peering_connection.ger-to-eng.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++_ France _++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
resource "aws_vpc" "vpc-fra" {
  provider             = aws.France
  cidr_block           = "192.168.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "France_VPC"
  }
}

# Create Internet Gateway and Attach it to VPC
resource "aws_internet_gateway" "internet-gateway-fra" {
  provider = aws.France
  vpc_id   = aws_vpc.vpc-fra.id
  tags = {
    Name = "France_internet_gateway"
  }
}

# Create Public Subnet
resource "aws_subnet" "public-subnet-france" {
  provider                = aws.France
  vpc_id                  = aws_vpc.vpc-fra.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-france"
  }
}

# Create Route Table and Add Public Route
resource "aws_route_table" "public-route-table-fra" {
  provider = aws.France
  vpc_id   = aws_vpc.vpc-fra.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway-fra.id
  }
  tags = {
    Name = "France Route Table"
  }
}
# Add route table
resource "aws_route" "fra-to-ger" {
  provider                  = aws.France
  route_table_id            = aws_route_table.public-route-table-fra.id
  destination_cidr_block    = "10.0.1.0/24"
  vpc_peering_connection_id = aws_vpc_peering_connection.fra-to-ger.id
}
resource "aws_route" "fra-to-eng" {
  provider                  = aws.France
  route_table_id            = aws_route_table.public-route-table-fra.id
  destination_cidr_block    = "172.16.1.0/24"
  vpc_peering_connection_id = aws_vpc_peering_connection.eng-to-fra.id
}

# Associate Public Subnet to "Public Route Table"
resource "aws_route_table_association" "public-subnet-france-route-table-association" {
  provider       = aws.France
  subnet_id      = aws_subnet.public-subnet-france.id
  route_table_id = aws_route_table.public-route-table-fra.id
}

# Perring install
resource "aws_vpc_peering_connection" "fra-to-ger" {
  peer_owner_id = "561103389959"
  peer_vpc_id   = aws_vpc.vpc-fra.id
  vpc_id        = aws_vpc.vpc-ger.id
  peer_region   = "eu-west-3"
  tags = {
    Side = "Requester2"
  }
}
resource "aws_vpc_peering_connection_accepter" "accept-ger" {
  provider                  = aws.France
  vpc_peering_connection_id = aws_vpc_peering_connection.fra-to-ger.id
  auto_accept               = true

  tags = {
    Side = "Accepter2"
  }
}


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++_ London _++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Create VPC
resource "aws_vpc" "vpc-eng" {
  provider             = aws.England
  cidr_block           = "172.16.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "England_VPC"
  }
}

# Create Internet Gateway and Attach it to VPC
resource "aws_internet_gateway" "internet-gateway-eng" {
  provider = aws.England
  vpc_id   = aws_vpc.vpc-eng.id
  tags = {
    Name = "Englang_internet_gateway"
  }
}

# Create Public Subnet
resource "aws_subnet" "public-subnet-englang" {
  provider                = aws.England
  vpc_id                  = aws_vpc.vpc-eng.id
  cidr_block              = "172.16.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-englang"
  }
}

# Create Route Table and Add Public Route
resource "aws_route_table" "public-route-table-eng" {
  provider = aws.England
  vpc_id   = aws_vpc.vpc-eng.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway-eng.id
  }
  tags = {
    Name = "England Route Table"
  }
}
# Add route table
resource "aws_route" "eng-to-fra" {
  provider                  = aws.England
  route_table_id            = aws_route_table.public-route-table-eng.id
  destination_cidr_block    = "192.168.1.0/24"
  vpc_peering_connection_id = aws_vpc_peering_connection.eng-to-fra.id
}
resource "aws_route" "eng-to-ger" {
  provider                  = aws.England
  route_table_id            = aws_route_table.public-route-table-eng.id
  destination_cidr_block    = "10.0.1.0/24"
  vpc_peering_connection_id = aws_vpc_peering_connection.ger-to-eng.id
}

# Associate Public Subnet to "Public Route Table"
resource "aws_route_table_association" "public-subnet-england-route-table-association" {
  provider       = aws.England
  subnet_id      = aws_subnet.public-subnet-englang.id
  route_table_id = aws_route_table.public-route-table-eng.id
}

# Perring install
resource "aws_vpc_peering_connection" "eng-to-fra" {
  provider      = aws.France
  peer_owner_id = "561103389959"
  peer_vpc_id   = aws_vpc.vpc-eng.id
  vpc_id        = aws_vpc.vpc-fra.id
  peer_region   = "eu-west-2"
  tags = {
    Side = "Requester1"
  }
}
resource "aws_vpc_peering_connection_accepter" "accept-fra" {
  provider                  = aws.England
  vpc_peering_connection_id = aws_vpc_peering_connection.eng-to-fra.id
  auto_accept               = true

  tags = {
    Side = "Accepter1"
  }
}
