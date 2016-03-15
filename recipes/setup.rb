# encoding: UTF-8

# Abstract the specific configurations by providers
include_recipe 'cloud-provisioning::_settings'

aws_key_pair 'cloud-provisioner' do
  private_key_options({
    format: :pem,
    type: :rsa,
    regenerate_if_different: true
  })
  allow_overwrite true
end

include_recipe 'cloud-provisioning::setup_sql'
