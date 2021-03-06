resource_name :awscli_setup

property :resource_title, String, name_property: true
property :aws_region, default: lazy { node['commons']['awscli']['aws_region'] }
property :credentials_databag, default: lazy { node['commons']['awscli']['credentials_databag'] }
property :credentials_databag_item, String, default: lazy { node['commons']['awscli']['credentials_databag_item'] }
property :credentials_parent_path, default: lazy { node['commons']['awscli']['credentials_parent_path'] }
property :force_cmd, kind_of: [TrueClass, FalseClass], default: lazy { node['commons']['force_awscli_commandline_install'] || false }
property :aws_config_file, default: lazy { "#{node['commons']['awscli']['credentials_parent_path']}/credentials" }
property :purge_settings, kind_of: [TrueClass, FalseClass], default: lazy { node['commons']['maven']['purge_settings'] || false }

default_action :create

action :create do
  if force_cmd
    package 'python-pip' do
      action :install
    end
    execute 'install-awscli' do
      command 'pip install awscli'
      not_if 'pip list | grep awscli'
    end
  else
    include_recipe 'python::default'
    python_pip 'awscli'
  end

  directory credentials_parent_path do
    mode '0755'
    action :create
  end

  begin
    aws_credentials = data_bag_item(credentials_databag, credentials_databag_item)
    aws_config = "[default]
region=#{aws_region}
aws_access_key_id=#{aws_credentials['aws_access_key_id']}
aws_secret_access_key=#{aws_credentials['aws_secret_access_key']}"

    file aws_config_file do
      content aws_config
    end
  rescue
    Chef::Log.warn('Cannot find databag ' + credentials_databag + ' with item ' + credentials_databag_item + '; skipping ' + aws_config_file + ' file creation')
  end

  directory credentials_parent_path do
    action :delete
    recursive true
    only_if { purge_settings }
  end
end
