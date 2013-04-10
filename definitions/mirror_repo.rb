#
# Cookbook Name::	mirror_repo.rb
# Description::		Definition to add remote repository to mrepo
# Recipe::				mrepo
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#

# Example of use:
# mirror_repo 'CentOS-6' do
#   description 'Repository CentOS 5.6 32 bit'
#   release   '5.6'
#   arch      'i386'
#   metadata  
#   ensure    'present'
#   update    'nightly'
#   urls      {
#     :addons      => 'rsync://mirrors.kernel.org/centos/$release/addons/$arch/',
#     :centosplus  => 'rsync://mirrors.kernel.org/centos/$release/centosplus/$arch/',
#     :updates     => 'rsync://mirrors.kernel.org/centos/$release/updates/$arch/',
#   }
define  :mirror_repo,
        :description => nil,
        :release     => nil,
        :arch        => nil,
        :metadata    => nil,
        :iso         => nil,
        :urls        => nil,
        :hour        => '0',
        :ensure      => 'present',
        :update      => 'weekly',
        :gentimeout  => '3600' do

  include_recipe 'mrepo'

  acceptable_ensure   = [ 'present', 'absent' ]
  acceptable_metadata = [ 'yum', 'apt', 'repomd', 'repoview' ]
  acceptable_update   = [ 'now', 'weekly', 'nightly', 'never' ]
  acceptable_arch     = [ 'i386', 'i586', 'x86_64', 'ppc', 's390', 's390x', 'ia64' ]


  # --[ Get the parameters ]--
  release        = params[:release]
  iso            = params[:iso]
  urls           = params[:urls]
  mirror_name    = params[:name]
  create         = params[:ensure]
  update         = params[:update]
  src_dir        = node[:mrepo][:srcdir]
  www_dir        = "#{node[:mrepo][:wwwdir]}/#{mirror_name}"
  mrepo_dir_conf = "#{node[:mrepo][:config_dir]}/#{mirror_name}.conf"
  metadata       = if params[:metadata].is_a? Array; then params[:metadata].join(' '); else params[:metadata]; end

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
    :invalide_ensure => {
      :title => 'ensure',
      :value => [ create ] - acceptable_ensure,
    },
    :invalide_update => {
      :title => 'update',
      :value => [ update ] - acceptable_update,
    },
    :invalide_metadata => {
      :title => 'metadata',
      :value => array_meta - acceptable_metadata,
    },
    :invalide_arch => {
      :title => 'arch',
      :value => array_arch - acceptable_arch,
    },
  }

  invalide_options = %w(invalide_ensure invalide_metadata invalide_update invalide_arch)
  invalide_options.each do |option|
    if invalide_array[:"#{option}"][:value].size == 1
      Chef::Application.fatal! "The passed value 'invalide_array[:"#{option}"][:value]' for the option 'invalide_array[:"#{option}"][:title]' is not an acceptable value"
    end
  end

  if create == 'present'

    Chef::Log.info ">>> [:mirror_repo] Adding repo '#{mirror_name}'"
    template mrepo_dir_conf do
      source 'repo.conf.erb'
      owner 'root'
      group 'root'
      mode  '0644'
      variables(
        :name     => mirror_name,
        :release  => release,
        :arch     => arch,
        :metadata => metadata,
        :iso      => iso,
        :urls     => urls,
      )
      notifies :run, "execute[Generate mrepo for #{mirror_name}]"
    end

    Chef::Log.info ">>> [:mirror_repo] Adding repo '#{mirror_name}'"
    execute "Generate mrepo for #{mirror_name}" do
      path "['/usr/bin','/bin']"
      command "mrepo -g #{mirror_name}"
      cwd src_dir
      user 'root'
      group 'root'
      timeout gentimeout
    
      action :nothing
    end

    Chef::Log.info ">>> [:mirror_repo] Creating web directory for #{mirror_name}"
    directory www_dir do
      owner "root"
      group "root"
      mode "0755"
    
      action :create
    end

    if params[:update] =~ /(?i-mx:now)/
      # --[ Update repo is now ]--
      Chef::Log.info ">>> [:mirror_repo] Synchronizing now repo '#{mirror_name}'"
      execute "Synchronize repo #{mirror_name}" do
        path "['/usr/bin','/bin']"
        command "/usr/bin/mrepo -qgu #{mirror_name}"
        cwd src_dir
        user "root"
        group "root"
        timeout gentimeout
      
        action :run
      end

      # --[ Removing Crons ]--
      Chef::Log.info ">>> [:mirror_repo] Removing any remaining cron for '#{mirror_name}'"
      cron "Nightly synchronize repo #{mirror_name}" do

        action :delete
      end
      
      cron "Weekly synchronize repo #{mirror_name}" do

        action :delete
      end

    elsif params[:update] =~ /(?i-mx:nightly)/
      Chef::Log.info ">>> [:mirror_repo] Setting nightly cron for '#{mirror_name}'"
      # --[ Update repo is done every night ]--
      cron "Nightly synchronize repo #{mirror_name}" do
        hour params[:hour]
        minute '0'
        path "/bin:/usr/bin"
        command "/usr/bin/mrepo -qgu #{mirror_name}"
        user "root"
        home src_dir
        shell "/bin/bash"

        action :create
      end

      cron "Weekly synchronize repo #{mirror_name}" do

        action :delete
      end

    elsif params[:update] =~ /(?i-mx:weekly)/
      Chef::Log.info ">>> [:mirror_repo] Setting weekly cron for '#{mirror_name}'"
      # --[ Update repo is done every week ]--
      cron "Weekly synchronize repo #{mirror_name}" do
        weekday '0'
        hour params[:hour]
        minute '0'
        path "/bin:/usr/bin"
        command "/usr/bin/mrepo -qgu #{mirror_name}"
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
    Chef::Log.info ">>> [:mirror_repo] Removing repo '#{mirror_name}'"
    Chef::Log.info ">>> [:mirror_repo] Umounting iso for repo '#{mirror_name}'"
    execute "Unmount any mirrored ISOs for #{mirror_name}" do
      path "['/usr/bin', '/bin', '/usr/sbin', '/sbin']"
      command "umount #{www_dir}/disc*"
      user "root"
      group "root"
      if_only "/bin/mount | /bin/grep #{www_dir}/disk"
    end

    Chef::Log.info ">>> [:mirror_repo] Removing files for repo '#{mirror_name}'"
    dir_to_remove = %W(www_dir mrepo_dir_conf)
    dir_to_remove.each do |dir|
      directory dir do
        recursive true
      
        action :delete
      end
    end

    Chef::Log.info ">>> [:mirror_repo] Removing any remaining cron for '#{mirror_name}'"
    cron "Nightly synchronize repo #{mirror_name}" do

      action :delete
    end
  end
end
