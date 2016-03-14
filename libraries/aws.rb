# encoding: UTF-8

require_relative '_base'

module Cloud
  module Provisioning
    #
    # AWS class for AWS Provisioning Driver
    #
    # Specify all the methods a Provisioning Driver should implement
    class Aws < Cloud::Provisioning::Base
      attr_accessor :node
      attr_accessor :ssh_username
      alias username ssh_username

      # Create a new Provisioning Driver Abstraction
      #
      # @param node [Chef::Node]
      def initialize(node)
        require 'chef/provisioning/aws_driver'

        Cloud::Helpers.check_attribute?(
          node['cloud-provisioning'][driver],
          "node['cloud-provisioning']['#{driver}']"
        )
        @node = node
        @driver_hash = @node['cloud-provisioning'][driver]

        @driver_hash.each do |attr, value|
          singleton_class.class_eval { attr_accessor attr }
          instance_variable_set("@#{attr}", value)
        end
      end

      # Return the machine options to use.
      #
      # @return [Hash] the machine_options for the specific driver
      def machine_options
        opts = {
          convergence_options: {
            bootstrap_proxy: @bootstrap_proxy,
            chef_config: @chef_config,
            chef_version: @chef_version,
            install_sh_path: @install_sh_path
          },
          bootstrap_options: {
            instance_type: @flavor,
            key_name: @key_name,
            security_group_ids: @security_group_ids,
          },
          ssh_username: @ssh_username,
          image_id: @image_id,
          use_private_ip_for_ssh: @use_private_ip_for_ssh
        }

        # Add any optional machine options
        require 'chef/mixin/deep_merge'
        if @subnet_id
          opts = Chef::Mixin::DeepMerge.hash_only_merge(opts,
            bootstrap_options: { subnet_id: @subnet_id })
        end

        opts
      end

      # Create a array of machine_options specifics to a component
      #
      # @param component [String] component name
      # @param count [Integer] component number
      # @return [Array] specific machine_options for the specific component
      def specific_machine_options(component, _count = nil)
        return [] unless @node['cloud-provisioning'][component]
        options = []
        options << { bootstrap_options: { instance_type: @node['cloud-provisioning'][component]['flavor'] } } if @node['cloud-provisioning'][component]['flavor']
        options << { bootstrap_options: { security_group_ids: @node['cloud-provisioning'][component]['security_group_ids'] } } if @node['cloud-provisioning'][component]['security_group_ids']
        options << { image_id: @node['cloud-provisioning'][component]['image_id'] } if @node['cloud-provisioning'][component]['image_id']
        options << { aws_tags: @node['cloud-provisioning'][component]['aws_tags'] } if @node['cloud-provisioning'][component]['aws_tags']
        # Specify more specific machine_options to add
        options
      end

      # Return the Provisioning Driver Name.
      #
      # @return [String] the provisioning driver name
      def driver
        'aws'
      end

      # Return the ipaddress from the machine.
      #
      # @param node [Chef::Node]
      # @return [String] an ipaddress
      def ipaddress(node)
        @use_private_ip_for_ssh ? node['ec2']['local_ipv4'] : node['ec2']['public_ipv4']
      end
    end
  end
end
