# encoding: UTF-8

require 'fileutils'
require 'erb'
require 'json'
require 'chef-config/config'

# String Colorization
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def pink
    colorize(35)
  end
end

# Provisioning Environment for ERB Rendering
class ProvisioningEnvironment
  def initialize(name, options)
    options.each_pair do |key, value|
      instance_variable_set('@' + key.to_s, value)
    end
    @name = name
    @data = json
  end

  def self.template
    '<%= JSON.pretty_generate(@data) %>'
  end

  def json
    {
      'name' => @name,
      'description' => 'Auto-Provisioned Stuff',
      'json_class' => 'Chef::Environment',
      'chef_type' => 'environment',
      'override_attributes' => {
        'auto-provisioning' => {
          'id' => @cluster_id,
          'cloud' => @cloud_provider,
          @cloud_provider => @cloud,
          'web_server' => (@web_server if @web_server && ! @web_server.empty?),
          'app_server' => (@app_server if @app_server && ! @app_server.empty?),
          'db_server' => (@db_server if @db_server && ! @db_server.empty?)
        }.delete_if { |_k, v| v.nil? }
      }
    }
  end

  def do_binding
    binding
  end
end

ENV['CHEF_ENV'] ||= 'test'
ENV['CHEF_ENV_FILE'] = "environments/#{ENV['CHEF_ENV']}.json"

# Validate the environment file
#
# If the environment file does not exist or it has syntax errors fail fast
def validate_environment
  unless File.exist?(ENV['CHEF_ENV_FILE'])
    puts 'You need to configure an Environment under "environments". ' \
         'Check the README.md'.red
    puts 'You can use the "generate_env" task to auto-generate one:'
    puts '  # rake setup:generate_env'
    puts "\nOr if you just have a different chef environment name run:"
    puts "  # export CHEF_ENV=#{'my_new_environment'.yellow}"
    raise
  end

  begin
    JSON.parse(File.read(ENV['CHEF_ENV_FILE']))
  rescue JSON::ParserError
    puts "You have syntax errors on the environment file '#{ENV['CHEF_ENV_FILE']}'".red
    puts 'Please fix the problems and re run the task.'
    raise
  end
end

def chef_apply(recipe)
  succeed = system "chef exec chef-apply recipes/#{recipe}.rb"
  raise 'Failed executing ChefApply run' unless succeed
end

def provisioning_data_dir
  File.expand_path('.chef/provisioning-data')
end

def chef_config
  knife_rb = File.join(provisioning_data_dir, 'knife.rb')
  ChefConfig::Config.from_file(knife_rb) if File.exist?(knife_rb)
  ChefConfig::Config
end

def chef_server_url
  chef_config[:chef_server_url]
end

def chefdk_version
  @chef_dk_version ||= `chef -v`.split("\n").first.split.last
rescue
  puts 'ChefDk was not found'.red
  puts 'Please install it from: https://downloads.chef.io/chef-dk'.yellow
  raise
end

def chef_zero(recipe)
  validate_environment
  succeed = system "chef exec chef-client -z -o cloud-provisioning::#{recipe} -E #{ENV['CHEF_ENV']}"
  raise 'Failed executing ChefZero run' unless succeed
end

def render_environment(environment, options)
  ::FileUtils.mkdir_p 'environments'

  env_file = File.open("environments/#{environment}.json", 'w+')
  env_file << ERB.new(ProvisioningEnvironment.template)
    .result(ProvisioningEnvironment.new(environment, options).do_binding)
  env_file.close

  puts File.read("environments/#{environment}.json")
end

def bool(string)
  case string
  when 'no'
    false
  when 'yes'
    true
  else
    string
  end
end

def ask_for(thing, default = nil)
  thing = "#{thing} [#{default.yellow}]: " if default
  stdin = nil
  loop do
    print thing
    stdin = STDIN.gets.strip
    case default
    when 'no', 'yes'
      break if stdin.empty? || stdin.eql?('no') || stdin.eql?('yes')
      print 'Answer (yes/no) '
    when nil
      break unless stdin.empty?
    else
      break
    end
  end
  bool(stdin.empty? ? default : stdin)
end

def hint
  @hint ||= begin
    File.exist?('.hints.toml') ? Hashie::Mash.load('.hints.yml') : {}
  rescue ArgumentError => e
    raise "There was an error reading the hints file: #{e.message}"
  end
end

def msg(string)
  puts "\n#{string}\n".yellow
end

Rake::TaskManager.record_task_metadata = true

namespace :setup do
  desc 'Generate a Chef Infrastructure Provisioning Environment'
  task :generate_env do
    msg 'Gathering Chef Infrastructure Provisioning Environment Information'
    puts 'Provide the following information to generate your environment.'

    options = {}
    puts "\nGlobal Attributes".pink
    # Environment Name
    environment = ask_for('Environment Name', 'test')

    if File.exist? "environments/#{environment}.json"
      puts "ERROR: Environment environments/#{environment}.json already exist".red
      exit 1
    end

    options['cluster_id'] = ask_for('Cluster ID', environment)
    puts "\nAvailable Cloud Provider: [ aws ]"
    options['cloud_provider'] = ask_for('Cloud Provider', 'aws')
    options['cloud'] = {}
    case options['cloud_provider']
    when 'aws'
      puts "\nAvailable regions: [ us-west-2 | us-east-1 ]"
      options['cloud']['region'] = ask_for('Region', 'us-west-2')
      unless options['cloud']['region'] =~ /^us-west-2$/i ||
             options['cloud']['region'] =~ /^us-east-1$/i
        puts 'ERROR: Unsupported Region specified.'.red
        puts 'Available Region are [ us-west-2 | us-east-1 ]'.yellow
        exit 1
      end

    else
      puts 'ERROR: Cloud Provider.'.red
      puts 'Available Drivers are [ aws ]'.yellow
      exit 1
    end

    puts "\nAvailable Application Profiles: [ Web | App | DB ]"
    options['app_profile'] = ask_for('Application Profile', 'db')
    case options['app_profile']
# WEB SERVER
    when /^(web|web\sserver)$/i
      puts "\nWeb Server".pink
      options['web_server'] = {}

      puts "\nAvailable Web Server types: [ iis | apache ]"
      options['web_server']['type'] = ask_for('Web Server type', 'apache')
      case options['web_server']['type']
      when /^iis$/i
        # get AMI
      when /^apache$/i
      else
        puts 'ERROR: Unsupported Web Server type specified.'.red
        puts 'Available Web Server types are [ iis | apache ]'.yellow
        exit 1
      end

      puts "\nInstance Size: [ small | medium | large ]"
      options['web_server']['size'] = ask_for('Instance Size', 'small')
      case options['web_server']['size']
      when /^small$/i
      when /^medium$/i
      when /^large$/i
      else
        puts 'ERROR: Unsupported Size specified.'.red
        puts 'Available Sizes are [ small | medium | large ]'.yellow
        exit 1
      end

# APPLICATION SERVER
    when /^(app|application\sserver|app\sserver)$/i
      puts "\nApplication Server".pink
      options['app_server'] = {}

      puts "\nOperating System: [ windows | linux ]"
      options['app_server']['os'] = ask_for('Operating System', 'linux')
      case options['app_server']['os']
      when /^windows$/i
      when /^linux$/i
      else
        puts 'ERROR: Unsupported OS specified.'.red
        puts 'Available OS [ windows | linux ]'.yellow
        exit 1
      end

      puts "\nInstance Size: [ small | medium | large ]"
      options['app_server']['size'] = ask_for('Instance Size', 'small')
      case options['app_server']['size']
      when /^small$/i
      when /^medium$/i
      when /^large$/i
      else
        puts 'ERROR: Unsupported Size specified.'.red
        puts 'Available Sizes are [ small | medium | large ]'.yellow
        exit 1
      end

# DATABASE
    when /^(db|data\sbase\sserver|database\sserver|db\sserver)$/i
      puts "\nDatabase Server".pink
      options['db_server'] = {}

      puts "\nDatabase Server: [ oracle | mssql ]"
      options['db_server']['type'] = ask_for('Database Server', 'oracle')
      case options['db_server']['type']
      when /^oracle$/i
      when /^mssql$/i
      else
        puts 'ERROR: Unsupported Database specified.'.red
        puts 'Available Database [ oracle | mssql ]'.yellow
        exit 1
      end

      puts "\nInstance Size: [ small | medium | large ]"
      options['db_server']['size'] = ask_for('Instance Size', 'small')
      case options['db_server']['size']
      when /^small$/i
      when /^medium$/i
      when /^large$/i
      else
        puts 'ERROR: Unsupported Size specified.'.red
        puts 'Available Sizes are [ small | medium | large ]'.yellow
        exit 1
      end

# FAIL
    else
      puts 'ERROR: Unsupported application specified.'.red
      puts 'Available application types are [ Web | App | DB ]'.yellow
      exit 1
    end


    options['app_type']['tags']['abc_id'] = ask_for('ABC ID: ')
    loop do
      unless options['app_type']['tags']['abc_id']
        puts 'You must specify an ABC ID'.red
      end
    end

    options['app_type']['tags']['bci'] = ask_for('BCI: ')
    loop do
      unless options['app_type']['tags']['bci']
        puts 'You must specify an BCI'.red
      end
    end

    options['app_type']['tags']['owner'] = ask_for('Owner: ')
    loop do
      unless options['app_type']['tags']['owner']
        puts 'You must specify an owner'.red
      end
    end

    msg "Rendering Chef Infrastructure Provisioning Environment => environments/#{environment}.json"

    render_environment(environment, options)

    puts "\nExport your new environment by executing:".yellow
    puts "  # export CHEF_ENV=#{environment.green}\n"
  end

  desc 'Install all the prerequisites on you system'
  task :prerequisites do
    msg 'Verifying ChefDK version'
    if Gem::Version.new(chefdk_version) < Gem::Version.new('0.10.0')
      puts "Running ChefDK version #{chefdk_version}".red
      puts 'The required version is >= 0.10.0'.red
      raise
    else
      puts "Running ChefDK version #{chefdk_version}".green
    end

    msg 'Configuring the provisioner node'
    chef_apply 'provisioner'

    msg 'Download and vendor the necessary cookbooks locally'
    system 'chef exec berks vendor cookbooks'

    msg "Current chef environment => #{ENV['CHEF_ENV_FILE']}"
    validate_environment
  end

  desc 'Setup the Chef Infrastructure Provisioning Environment'
  task cluster: [:prerequisites] do
    msg 'Setup the Chef Infrastructure Provisioning Environment'
    chef_zero 'setup'
  end

  desc 'Setup a SQL Server'
  task :sql_server do
    msg 'Create a SQL Server'
    chef_zero 'setup_sql_server'
  end
end

namespace :maintenance do
  desc 'Update cookbook dependencies'
  task :update do
    msg 'Updating cookbooks locally'
    system 'chef exec berks update'
  end

  desc 'Clean the cache'
  task :clean_cache do
    FileUtils.rm_rf('.chef/local-mode-cache')
    FileUtils.rm_rf('cookbooks/')
  end
end

namespace :destroy do
  desc 'Destroy Everything'
  task :all do
    chef_zero 'destroy_all'
  end
end

namespace :info do
  desc 'List nodes in the Chef Infrastructure Provisioning Environment'
  task :list_core_services do
    system 'knife search node \'name:*server* OR name:node*\' -a ipaddress'
    puts "Chef Server URL: #{chef_server_url}"
  end
end

task default: [:help]
task :help do
  puts "\nChef Infrastructure Provisioning Environment Helper".green
  puts "\nSetup Tasks".pink
  puts 'The following tasks should be used to set up your environment'.yellow
  Rake.application.options.show_tasks = :tasks
  Rake.application.options.show_task_pattern = /setup/
  Rake.application.display_tasks_and_comments
  puts "\nMaintenance Tasks".pink
  puts 'The following tasks should be used to maintain your environment'.yellow
  Rake.application.options.show_task_pattern = /maintenance/
  Rake.application.display_tasks_and_comments
  puts "\nDestroy Tasks".pink
  puts 'The following tasks should be used to destroy your environment'.yellow
  Rake.application.options.show_task_pattern = /destroy/
  Rake.application.display_tasks_and_comments
  puts "\nCluster Information".pink
  puts 'The following tasks should be used to get information about your environment'.yellow
  Rake.application.options.show_task_pattern = /info/
  Rake.application.display_tasks_and_comments
  puts "\nTo switch your environment run:"
  puts "  # export CHEF_ENV=#{'my_environment_name'.yellow}\n"
end
