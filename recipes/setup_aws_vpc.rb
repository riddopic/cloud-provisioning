# encoding: UTF-8

include_recipe 'cloud-provisioning::_settings'

aws_dhcp_options 'ref-dhcp-options' do
  domain_name 'aws.amazon.com'
  domain_name_servers ['8.8.8.8', '8.8.4.4']
  ntp_servers ['8.8.8.8', '8.8.4.4']
  netbios_name_servers ['8.8.8.8', '8.8.4.4']
  netbios_node_type 2
  aws_tags generate_tags('aws_dhcp_options')
end

aws_vpc 'ref-vpc' do
  cidr_block '172.16.0.0/16'
  internet_gateway true
  instance_tenancy :default
  dhcp_options 'ref-dhcp-options'
  enable_dns_support true
  enable_dns_hostnames true
  aws_tags generate_tags('aws_vpc')
end

aws_route_table 'ref-main-route-table' do
  vpc 'ref-vpc'
  aws_tags generate_tags('aws_route_table')
end

aws_vpc 'ref-vpc' do
  main_route_table 'ref-main-route-table'
end

aws_route_table 'ref-public-route' do
  vpc 'ref-vpc'
  routes '0.0.0.0/0' => :internet_gateway
  aws_tags generate_tags('aws_route_table')
end

aws_network_acl 'ref-public-acl' do
  inbound_rules [
    { rule_number: 100, action: :allow, protocol: 6, cidr_block: '24.7.32.100/32', port_range: 80..80 },
    { rule_number: 110, action: :allow, protocol: 6, cidr_block: '24.7.32.100/32', port_range: 443..443 },
    { rule_number: 120, action: :allow, protocol: 6, cidr_block: '24.7.32.100/32', port_range: 22..22 },
    { rule_number: 140, action: :allow, protocol: 6, cidr_block: '0.0.0.0/0', port_range: 49152..65535 }
  ]
  outbound_rules [
    { rule_number: 100, action: :allow, protocol: 6, cidr_block: '0.0.0.0/0', port_range: 80..80 },
    { rule_number: 110, action: :allow, protocol: 6, cidr_block: '0.0.0.0/0', port_range: 443..443 },
    { rule_number: 140, action: :allow, protocol: 6, cidr_block: '0.0.0.0/0', port_range: 49152..65535 },
    { rule_number: 150, action: :allow, protocol: 6, cidr_block: '172.16.100.0/24', port_range: 22..22 }
  ]
  vpc 'ref-vpc'
  aws_tags generate_tags('aws_network_acl')
end

aws_subnet 'ref-public-subnet' do
  vpc 'ref-vpc'
  cidr_block '172.16.100.0/24'
  availability_zone 'us-west-2b'
  map_public_ip_on_launch true
  route_table 'ref-public-route'
  network_acl 'ref-public-acl'
  aws_tags generate_tags('aws_subnet')
end

aws_route_table 'ref-private-route' do
  vpc 'ref-vpc'
  aws_tags generate_tags('aws_route_table')
end

aws_network_acl 'ref-private-acl' do
  inbound_rules [
    { rule_number: 120, action: :allow, protocol: 6, cidr_block: '172.16.100.0/24', port_range: 22..22 },
    { rule_number: 140, action: :allow, protocol: 6, cidr_block: '0.0.0.0/0', port_range: 49152..65535 }
  ]
  outbound_rules [
    { rule_number: 100, action: :allow, protocol: 6, cidr_block: '0.0.0.0/0', port_range: 80..80 },
    { rule_number: 110, action: :allow, protocol: 6, cidr_block: '0.0.0.0/0', port_range: 443..443 },
    { rule_number: 120, action: :allow, protocol: 6, cidr_block: '172.16.100.0/24', port_range: 49152..65535 }
  ]
  vpc 'ref-vpc'
  aws_tags generate_tags('aws_network_acl')
end

aws_subnet 'ref-private-subnet' do
  vpc 'ref-vpc'
  cidr_block '172.16.200.0/24'
  availability_zone 'us-west-2b'
  map_public_ip_on_launch false
  route_table 'ref-private-route'
  network_acl 'ref-private-acl'
  aws_tags generate_tags('aws_subnet')
end

aws_key_pair 'ref-key-pair' do
  private_key_options({
    format: :pem,
    type: :rsa,
    regenerate_if_different: true
  })
  allow_overwrite true
end
