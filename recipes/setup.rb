# encoding: UTF-8

# Abstract the specific configurations by providers
include_recipe 'cloud-provisioning::_settings'

# Setup the AWS security groups
include_recipe 'cloud-provisioning::setup_security_group'

unless node['cloud-provisioning']['sql'].nil?
  include_recipe 'cloud-provisioning::setup_sql'
end

aws_key_pair 'cloud-provisioner' do
  private_key_options({
    format: :pem,
    type: :rsa,
    regenerate_if_different: true
  })
  allow_overwrite true
end
