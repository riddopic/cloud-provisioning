# encoding: UTF-8

default['cloud-provisioning'].tap do |provisioning|
  #
  # Provisioning Driver
  provisioning['driver'] = 'aws'
  #
  # The Cluster Name which will be use to define all default hostnames
  provisioning['id'] = nil
  #
  # Common Cluster Recipes
  provisioning['common_recipes'] = []
  #
  # AWS Driver Attributes.
  provisioning['aws'] = {
    'key_name'               => ENV['USER'],
    'ssh_username'           => nil,
    'bootstrap_proxy'        => ENV['HTTPS_PROXY'] || ENV['HTTP_PROXY']
  }
  #
  # SQL Server
  provisioning['sql-server'] = {
    'security_group_ids' => nil,
    'image_id'           => nil,
    'subnet_id'          => nil,
    'hostname'           => nil,
    'fqdn'               => nil,
    'flavor'             => 't2.medium',
    'recipes'            => [],
    'attributes'         => {}
  }
end
