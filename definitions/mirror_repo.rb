#
# Cookbook Name::	mrepo
# Description::		Definition to add remote repository to mrepo
# Recipe::				mirror_repo.rb
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#

# Example of use:
# mirror_repo 'CentOS-6' do
#   description 'Repository CentOS 5.6 32 bit'
#   release   '5.6'
#   arch      'i386'
#   metadata  [ 'repomd' , 'yum' ]
#   action    'create'
#   update    'nightly'
#   urls      ({
#     :addons      => 'rsync://mirrors.kernel.org/centos/$release/addons/$arch/',
#     :centosplus  => 'rsync://mirrors.kernel.org/centos/$release/centosplus/$arch/',
#     :updates     => 'rsync://mirrors.kernel.org/centos/$release/updates/$arch/',
#   })
# end

define  :mirror_repo,
        :description => nil,
        :release     => nil,
        :arch        => nil,
        :metadata    => nil,
        :key_url     => nil,
        :iso         => nil,
        :urls        => nil,
        :hour        => '0',
        :action      => 'create',
        :update      => 'weekly',
        :gentimeout  => '3600' do

  include_recipe 'mrepo'

  acceptable_action   = [ 'create', 'delete' ]
  acceptable_metadata = [ 'yum', 'apt', 'repomd', 'repoview' ]
  acceptable_update   = [ 'now', 'weekly', 'nightly', 'never', 'daily' ]
  acceptable_arch     = [ 'i386', 'i586', 'x86_64', 'ppc', 's390', 's390x', 'ia64' ]


  # --[ Get the parameters ]--
  release        = params[:release]
  iso            = params[:iso]
  key_url        = params[:key_url]
  urls           = params[:urls]
  mirror_name    = params[:name]
  create         = params[:action]
  update         = params[:update]
  description    = params[:description]
  gentimeout     = params[:gentimeout].to_i
  src_dir        = node[:mrepo][:srcdir]
  key_repo       = node[:mrepo][:keydir]
  www_dir        = "#{node[:mrepo][:wwwdir]}/#{mirror_name}"
  mrepo_dir_conf = "#{node[:mrepo][:config_dir]}/#{mirror_name}.conf"
  metadata       = if params[:metadata].is_a? Array; then params[:metadata].join(' '); else params[:metadata]; end
  
  # --[ Random number based on IP ]--
  ip1, ip2, ip3, ip4 = node[:ipaddress].split('.')
  minute_random      = (ip4.to_i * 256 + ip3.to_i )% 3600

  # --[ Meta could be an array ]--
  if params[:metadata].is_a? Array
    metadata   = params[:metadata].join(' ')
    array_meta = params[:metadata]
  else
    metadata   = params[:metadata]
    array_meta = [ metadata ]
  end

  # --[ Arch could also be an array ]--
  if params[:arch].is_a? Array
    arch       = params[:arch].join(' ')
    array_arch = params[:arch]
  else
    arch       = params[:arch]
    array_arch = [ arch ]
  end
  # --[ Check arguments ]--
  invalide_array = {
    :invalide_action => {
      :title      => 'action',
      :value      => [ create ] - acceptable_action,
      :acceptable => acceptable_action,
    },
    :invalide_update => {
      :title      => 'update',
      :value      => [ update ] - acceptable_update,
      :acceptable => acceptable_update,
    },
    :invalide_metadata => {
      :title      => 'metadata',
      :value      => array_meta - acceptable_metadata,
      :acceptable => acceptable_metadata,
    },
    :invalide_arch => {
      :title      => 'arch',
      :value      => array_arch - acceptable_arch,
      :acceptable => acceptable_arch,
    },
  }

  invalide_options = %w(invalide_action invalide_metadata invalide_update invalide_arch)
  invalide_options.each do |option|
    if invalide_array[:"#{option}"][:value].size == 1
      title      = invalide_array[:"#{option}"][:title]
      value      = invalide_array[:"#{option}"][:value]
      acceptable = invalide_array[:"#{option}"][:acceptable]
      Chef::Log.info " >>> [:mirror_repo] The passed value #{value} for the option [#{title}] is not an acceptable value for \"#{mirror_name}\""
      Chef::Application.fatal! ">>> [:mirror_repo] --> Valide argument are: #{acceptable}"
    end
  end

  if create == 'create'
    unless key_url.nil?
      key_name = /.*\/(.*)$/.match(key_url)[1]
      execute "Getting key file #{key_name}" do
        path ['/bin','/usr/bin']
        command "wget #{key_url} -O #{key_repo}/#{key_name}"
        creates "#{key_repo}/#{key_name}"
        user 'root'
        group 'root'
        timeout 3600

        action :run
      end
    end

    Chef::Log.info " >>> [:mirror_repo] Adding repo '#{mirror_name}'"
    template mrepo_dir_conf do
      source 'repo.conf.erb'
      cookbook 'mrepo'
      owner 'root'
      group 'root'
      mode  '0644'
      variables(
        :name        => mirror_name,
        :description => description,
        :release     => release,
        :arch        => arch,
        :metadata    => metadata,
        :iso         => iso,
        :urls        => urls,
      )
      notifies :run, "execute[Generate mrepo for #{mirror_name}]"
    end

    Chef::Log.info " >>> [:mirror_repo] Generating repo '#{mirror_name}'"
    execute "Generate mrepo for #{mirror_name}" do
      path ['/usr/bin','/bin']
      command "mrepo -g \"#{mirror_name}\""
      cwd src_dir
      user 'root'
      group 'root'
      timeout gentimeout
    
      action :nothing
    end

    directory www_dir do
      owner "root"
      group "root"
      mode "0755"
    
      action :create
    end

    if params[:update] =~ /(?i-mx:now)/
      # --[ Update repo is now ]--
      Chef::Log.info " >>> [:mirror_repo] Synchronizing now repo '#{mirror_name}'"
      execute "Synchronize repo #{mirror_name}" do
        path ['/usr/bin','/bin']
        command "/usr/bin/mrepo -gu \"#{mirror_name}\""
        cwd src_dir
        user "root"
        group "root"
        timeout gentimeout
      
        action :run
      end

      # --[ Removing Crons ]--
      cron "Nightly synchronize repo #{mirror_name}" do

        action :delete
      end
      
      cron "Weekly synchronize repo #{mirror_name}" do

        action :delete
      end

    elsif params[:update] =~ /(?i-mx:nightly|daily)/
      Chef::Log.info " >>> [:mirror_repo] Setting nightly cron for '#{mirror_name}'"
      # --[ Update repo is done every night ]--
      cron "Nightly synchronize repo #{mirror_name}" do
        hour params[:hour]
        minute minute_random
        path "/bin:/usr/bin"
        command "[ -f \"#{mrepo_dir_conf}\" ] && /usr/bin/mrepo -gu \"#{mirror_name}\""
        user "root"
        home src_dir
        shell "/bin/bash"

        action :create
      end

      cron "Weekly synchronize repo #{mirror_name}" do

        action :delete
      end

    elsif params[:update] =~ /(?i-mx:weekly)/
      Chef::Log.info " >>> [:mirror_repo] Setting weekly cron for '#{mirror_name}'"
      # --[ Update repo is done every week ]--
      cron "Weekly synchronize repo #{mirror_name}" do
        weekday '0'
        hour params[:hour]
        minute minute_random
        path "/bin:/usr/bin"
        command "[ -f \"#{mrepo_dir_conf}\" ] && /usr/bin/mrepo -gu \"#{mirror_name}\""
        user "root"
        home src_dir
        shell "/bin/bash"

        action :create
      end
      
      cron "Nightly synchronize repo #{mirror_name}" do

        action :delete
      end
    end
  else
    Chef::Log.info " >>> [:mirror_repo] Removing repo '#{mirror_name}'"
    Chef::Log.info " >>> [:mirror_repo] Umounting iso for repo '#{mirror_name}'"
    execute "Unmount any mirrored ISOs for #{mirror_name}" do
      path ['/usr/bin', '/bin', '/usr/sbin', '/sbin']
      command "umount #{www_dir}/disc*"
      user "root"
      group "root"
      if_only "/bin/mount | /bin/grep #{www_dir}/disk"
    end

    Chef::Log.info " >>> [:mirror_repo] Removing files for repo '#{mirror_name}'"
    dir_to_remove = %W(www_dir mrepo_dir_conf)
    dir_to_remove.each do |dir|
      directory dir do
        recursive true
      
        action :delete
      end
    end

    Chef::Log.info " >>> [:mirror_repo] Removing any remaining cron for '#{mirror_name}'"
    cron "Nightly synchronize repo #{mirror_name}" do

      action :delete
    end
  end
end
