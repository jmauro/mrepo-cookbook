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

define :mirror_repo,
         :action   => 'create',
         :cookbook => 'mrepo',
         :repo     => nil do

  include_recipe 'mrepo'

  acceptable_action   = [ 'create', 'delete' ]
  acceptable_update   = [ 'now', 'weekly', 'nightly', 'never', 'daily' ]


  # --[ Get the parameters ]--
  repo_name         = params[:name]
  repo_tags         = params[:repo].reject{|key, value| key == :name }
  gentimeout        = node[:mrepo][:mirror]['timeout'].to_i
  isodir            = node[:mrepo][:dir][:iso]
  keydir            = node[:mrepo][:dir][:key]
  srcdir            = node[:mrepo][:conf][:main]['srcdir']
  wwwdir            = node[:mrepo][:conf][:main]['wwwdir']
  confdir           = node[:mrepo][:conf][:main]['confdir']
  mrepo_config_file = "#{confdir}/#{repo_name}.conf"
  
  # --[ Random number based on IP ]--
  ip1, ip2, ip3, ip4 = node[:ipaddress].split('.')
  minute_random      = (ip4.to_i * 256 + ip3.to_i ) % 60

  # --[ Check arguments ]--
  array_action = [ repo_tags['action'] ]
  array_update = [ repo_tags['update'] ]
  invalid_array = {
    :invalid_action => {
      :title      => 'action',
      :value      => array_action - acceptable_action,
      :acceptable => acceptable_action,
    },
    :invalid_update => {
      :title      => 'update',
      :value      => array_update - acceptable_update,
      :acceptable => acceptable_update,
    },
  }

  # --[ Checks valid argument for manddatory options: 'update', 'action' ]--
  invalid_options = %w(invalid_action invalid_update)
  invalid_options.each do |option|
    if invalid_array[:"#{option}"][:value].size == 1
      title      = invalid_array[:"#{option}"][:title]
      value      = invalid_array[:"#{option}"][:value]
      acceptable = invalid_array[:"#{option}"][:acceptable]
      Chef::Log.info ">>> [:mirror_repo] The passed value #{value} for the option [#{title}] is not an acceptable value for \"#{repo_name}\""
      Chef::Log.info ">>> [:mirror_repo] --> Valide argument are: #{acceptable}"
      fail('>>> [:mirror_repo] ERROR: exiting chef run')
    end
  end

  if params[:action] == 'create'
    # --[ For each 'arch' create a configuration file different ]--
    log "Adding #{repo_name}" do
      message ">>> [:mirror_repo] Adding repo '#{repo_name}'"
      level :info

      action :nothing
    end
    template mrepo_config_file do
      cookbook params[:cookbook]
      source 'mrepo.conf.erb'
      owner 'root'
      group 'root'
      mode  '0644'
      variables(
        :section => repo_name,
        :mrepo   => repo_tags,
      )

      notifies :run, "execute[Generate mrepo for #{repo_name}]"
      notifies :write, "log[Adding #{repo_name}]"
    end


    unless repo_tags['key_url'].nil?
      key_url = repo_tags['key_url']
      key_name = /.*\/(.*)$/.match(key_url)[1]
      execute "Getting key file #{key_name}" do
        path ['/bin','/usr/bin']
        command "wget #{key_url} -O #{keydir}/#{key_name}"
        creates "#{keydir}/#{key_name}"
        user 'root'
        group 'root'
        timeout gentimeout

        action :run
      end
    end

    unless repo_tags['iso_url'].nil?
      iso_url = repo_tags['iso_url']
      iso_url.each do | iso_dvd |
        iso_name = /.*\/(.*)$/.match(iso_dvd)[1]
        execute "Getting iso: #{iso_name}" do
          path ['/bin','/usr/bin']
          command "wget #{iso_dvd} -O #{isodir}/#{iso_name}"
          creates "#{isodir}/#{iso_name}"
          user 'root'
          group 'root'
          timeout gentimeout

          action :run
        end
      end
    end

    log "Generating #{repo_name}" do
      message ">>> [:mirror_repo] Generating repo '#{repo_name}'"
      level :info

      action :nothing
    end
    execute "Generate mrepo for #{repo_name}" do
      path ['/usr/bin','/bin']
      command "mrepo -g \"#{repo_name}\""
      cwd srcdir
      user 'root'
      group 'root'
      timeout gentimeout

      action :nothing
      notifies :write, "log[Generating #{repo_name}]"
    end

    if repo_tags['update'] =~ /(?i-mx:now)/
      # --[ Update repo is now ]--
      log "Synchronizing #{repo_name}" do
        message ">>> [:mirror_repo] Synchronizing now repo '#{repo_name}'"
        level :info

        action :nothing
      end
      execute "Synchronize repo #{repo_name}" do
        path ['/usr/bin','/bin']
        command "/usr/bin/mrepo -gu \"#{repo_name}\""
        cwd srcdir
        user "root"
        group "root"
        timeout gentimeout

        action :run
        notifies :write, "log[Synchronizing #{repo_name}]"
      end

      # --[ Removing Crons ]--
      cron "Nightly synchronize repo #{repo_name}" do

        action :delete
      end

      cron "Weekly synchronize repo #{repo_name}" do

        action :delete
      end

    elsif repo_tags['update'] =~ /(?i-mx:nightly|daily)/
      # --[ Update repo is done every night ]--
      log "Setting nightly cron #{repo_name}" do
        message ">>> [:mirror_repo] Setting nightly cron for '#{repo_name}'"
        level :info

        action :nothing
      end

      cron "Nightly synchronize repo #{repo_name}" do
        hour '0'
        minute minute_random
        path "/bin:/usr/bin"
        command "[ -f \"#{mrepo_config_file}\" ] && (umount #{wwwdir}/#{repo_name}*/disc* 2> /dev/null || true ) && /usr/bin/mrepo -gu \"#{repo_name}\""
        user "root"
        home srcdir
        shell "/bin/bash"

        action :create
        notifies :write, "log[Setting nightly cron #{repo_name}]"
      end

      cron "Weekly synchronize repo #{repo_name}" do

        action :delete
      end

    elsif repo_tags['update'] =~ /(?i-mx:weekly)/
      log "Setting weekly cron #{repo_name}" do
        message ">>> [:mirror_repo] Setting weekly cron for '#{repo_name}'"
        level :info

        action :nothing
      end
      # --[ Update repo is done every week ]--
      cron "Weekly synchronize repo #{repo_name}" do
        weekday '0'
        hour '0'
        minute minute_random
        path "/bin:/usr/bin"
        command "[ -f \"#{mrepo_config_file}\" ] && (umount #{wwwdir}/#{repo_name}*/disc* || true ) && /usr/bin/mrepo -gu \"#{repo_name}\""
        user "root"
        home srcdir
        shell "/bin/bash"

        action :create
        notifies :write, "log[Setting weekly cron #{repo_name}]"
      end

      cron "Nightly synchronize repo #{repo_name}" do

        action :delete
      end
    end
  else
    # --[ Iso ]--
    log "Unmounting iso #{repo_name}" do
      message ">>> [:mirror_repo] Umounting iso for repo '#{repo_name}'"
      level :info

      action :nothing
    end
    execute "Unmount any mirrored ISOs for #{repo_name}" do
      path ['/usr/bin', '/bin', '/usr/sbin', '/sbin']
      command "umount #{wwwdir}/#{repo_name}*/disc*"
      user "root"
      group "root"
      only_if "/bin/mount | /bin/grep #{wwwdir}/#{repo_name} | grep disc"

      notifies :write, "log[Unmounting iso #{repo_name}]"
    end

    # --[ Directory ]--
    log "Removing dir #{repo_name}" do
      message ">>> [:mirror_repo] Removing directory for repo '#{repo_name}'"
      level :info

      action :nothing
    end
    dir_to_remove = %W("#{wwwdir}/#{repo_name}" "#{srcdir}/#{repo_name}")
    dir_to_remove.each do |dir|
      directory "#{dir}*" do
        recursive true

        action :delete
        notifies :write, "log[Removing dir #{repo_name}]"
      end
    end

    # --[ Configuration files ]--
    log "Removing config #{repo_name}" do
      message ">>> [:mirror_repo] Removing files for repo '#{repo_name}'"
      level :info

      action :nothing
    end
    file mrepo_config_file do

      action :delete
      notifies :write, "log[Removing config #{repo_name}]"
    end

    # --[ Crontabs ]--
    log "Removing cron #{repo_name}" do
      message ">>> [:mirror_repo] Removing any remaining cron for '#{repo_name}'"
      level :info

      action :nothing
    end

    cron "Nightly synchronize repo #{repo_name}" do

      action :delete
      notifies :write, "log[Removing cron #{repo_name}]"
    end

    cron "Weekly synchronize repo #{repo_name}" do

      action :delete
    end
  end
end
