#
# Cookbook Name::	mirror_repo.rb
# Description::		Definition to add remote repository to mrepo
# Recipe::				mrepo
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#

define  :mirror_repo,
        :description,
        :release,
        :arch,
        :metadata,
        :iso,
        :urls,
        :hour         => '0',
        :ensure       => 'present',
        :update       => 'weekly',
        :gentimeout   => '3600' do

  include_recipe 'mrepo'

  # --[ Get the parameters ]--
  mirror_name    = params[:name]
  mrepo_dir_conf = "#{node[:mrepo][:config_dir]}/#{mirror_name}.conf"
  src_dir = node[:mrepo][:srcdir]
  www_dir = "#{node[:mrepo][:wwwdir]}/#{mirror_name}"

  if params[:ensure] == 'present'
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
    dir_to_remove = %W( www_dir mrepo_dir_conf)
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
