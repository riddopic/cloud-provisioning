# encoding: UTF-8

include_recipe 'cloud-provisioning::_settings'

machine sql_server_hostname do
  chef_server lazy {
    {
      chef_server_url: '54.187.211.135',
      options: {
        client_name: 'provisioner',
        signing_key_filename: File.expand_path('~/chef-repo/server-provisioning/.chef/provisioning-data/provisioner.pem')
      }
    }
  }
  provisioning.specific_machine_options('sql_server').each do |option|
    add_machine_options option
  end
  files lazy {
    {
      "/etc/chef/trusted_certs/#{chef_server_fqdn}.crt" =>
        "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_fqdn}.crt"
    }
  }
  action :converge
end
