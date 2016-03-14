# encoding: UTF-8

module Cloud
  module Helpers
    #
    # SQL Server Module
    #
    # This module provides helpers related to the Sql Component
    module Sql
      module_function

      # Get the Hostname of the SQL Server Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return hostname [String] The hostname of the SQL Server server
      def sql_server_hostname(node)
        Cloud::Helpers::Component.component_hostname(node, 'sql')
      end

      # Returns the FQDN of the SQL Server Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] SQL Server FQDN
      def sql_server_fqdn(node)
        @sql_server_fqdn ||=
          Cloud::Helpers::Component.component_fqdn(node, 'sql')
      end

      # Generates the SQL Server Server Attributes
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Hash] SQL Server attributes for a machine resource
      def sql_server_attributes(node)
        return {} unless sql_enabled?(node)

        Chef::Mixin::DeepMerge.hash_only_merge(
          Cloud::Helpers::Component.component_attributes(node, 'sql'),
          'chef-server-12' => {
            'sql' => {
              'fqdn' => sql_server_fqdn(node)
            }
          }
        )
      end

      # Activate the SQL Server Component
      # This method will touch a lock file to activate the SQL Server component
      #
      # @param node [Chef::Node] Chef Node object
      def activate_sql(node)
        FileUtils.touch(sql_lock_file(node))
      end

      # SQL Server Lock File
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] The PATH of the SQL Server lock file
      def sql_lock_file(node)
        "#{Cloud::Helpers.provisioning_data_dir(node)}/sql"
      end

      # Verify the state of the SQL Server Component
      # If the lock file exist, then we have the SQL Server component enabled,
      # otherwise it is NOT enabled yet.
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Bool] The state of the SQL Server component
      def sql_enabled?(node)
        File.exist?(sql_lock_file(node))
      end
    end
  end

  # Module that exposes multiple helpers
  module DSL
    # Hostname of the SQL Server Server
    def sql_server_hostname
      Cloud::Helpers::Sql.sql_server_hostname(node)
    end

    # FQDN of the SQL Server Server
    def sql_server_fqdn
      Cloud::Helpers::Sql.sql_server_fqdn(node)
    end

    # SQL Server Server Attributes
    def sql_server_attributes
      Cloud::Helpers::Sql.sql_server_attributes(node)
    end

    # Activate the SQL Server Component
    def activate_sql
      Cloud::Helpers::Sql.activate_sql(node)
    end

    # SQL Server Lock File
    def sql_lock_file
      Cloud::Helpers::Sql.sql_lock_file(node)
    end

    # Verify the state of the SQL Server Component
    def sql_enabled?
      Cloud::Helpers::Sql.sql_enabled?(node)
    end
  end
end
