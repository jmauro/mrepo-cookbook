#
# Cookbook Name::	mrepo
# Description::		Recipe to mirror any repository with 'mrepo'
# Recipe::				mirror.rb
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#
#

include_recipe 'mrepo'

# --[ Default settings from 'mrepo' from configuration file ]--
srcdir  = node[:mrepo][:conf][:main]['srcdir']
wwwdir  = node[:mrepo][:conf][:main]['wwwdir']
confdir = node[:mrepo][:conf][:main]['confdir']

# --[ Default settings from 'mrepo' from default attributs ]--
keydir  = node[:mrepo][:dir][:key]
isodir  = node[:mrepo][:dir][:iso]

# --[ Loading default ]--
gentimeout = node[:mrepo][:mirror]['timeout'].to_i

execute 'Checking loop device number' do
  path [ '/sbin', '/usr/sbin', '/bin','/usr/bin', ]
  # --[ Create 256 loop devices ]--
  command 'MAKEDEV -v /dev/loop'
  not_if 'test -r /dev/loop255'

  action :run
end

node[:mrepo][:repo].each do | repo_name, repo_tags |
  minute_random     = ( node[:mrepo][:mirror]['minute_ip'] + repo_name.sum ) % 60
  array_action      = [ repo_tags['action'] ]
  array_update      = [ repo_tags['update'] ]
  mrepo_config_file = "#{confdir}/#{repo_name}.conf"
  # --[ Check arguments ]--
  invalid_array = {
    :invalid_action => {
      :title      => 'action',
      :value      => array_action - node[:mrepo][:mirror][:options_set][:action],
      :acceptable => node[:mrepo][:mirror][:options_set][:action],
    },
    :invalid_update => {
      :title      => 'update',
      :value      => array_update - node[:mrepo][:mirror][:options_set][:update],
      :acceptable => node[:mrepo][:mirror][:options_set][:update],
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

  if repo_tags['action'] == 'create'
    # --[ For each 'arch' create a configuration file different ]--
    log "Adding #{repo_name}" do
      message ">>> [:mirror_repo] Adding repo '#{repo_name}'"
      level :info

      action :nothing
    end
    template mrepo_config_file do
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
        command "wget \"#{key_url}\" -O \"#{keydir}/#{key_name}\""
        user 'root'
        group 'root'
        timeout gentimeout
        not_if "test -s \"#{keydir}/#{key_name}\""

        action :run
      end
    end

    unless repo_tags['iso_url'].nil?
      iso_url = repo_tags['iso_url']
      iso_url.each do | iso_dvd |
        iso_name = /.*\/(.*)$/.match(iso_dvd)[1]
        # --[ Gettin md5sum file if given by user ]--
        unless repo_tags['iso_md5sum'].nil?
          execute "Getting md5sum for #{iso_name}" do
            command "curl -s #{repo_tags['iso_md5sum']} -o #{isodir}/#{iso_name}.md5sum"
            creates "#{isodir}/#{iso_name}.md5sum"
            user 'root'
            group 'root'

            action :run
          end
        end

        execute "Getting iso: #{iso_name}" do
          path ['/bin','/usr/bin']
          # --[ Make sure iso not mounted when downloading it ]--
          command "(losetup --show -f #{isodir}/#{iso_name} >/dev/null && umount #{isodir}/#{iso_name} 2>/dev/null >&2 || true) && curl -s #{iso_dvd} -o #{isodir}/#{iso_name}"
          cwd isodir
          # --[ Chekcing if md5sum file is present if not test the iso file ]--
          if ::File.exist?("#{isodir}/#{iso_name}.md5sum")
            not_if "cd #{isodir} && grep #{iso_name} #{iso_name}.md5sum | md5sum -c"
          else
            creates "#{isodir}/#{iso_name}"
          end
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
      command "mrepo -gf \"#{repo_name}\""
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
        command "/usr/bin/mrepo -gfu \"#{repo_name}\""
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
        command "[ -f \"#{mrepo_config_file}\" ] && (umount #{wwwdir}/#{repo_name}*/disc* 2> /dev/null || true ) && /usr/bin/mrepo -gfu \"#{repo_name}\" > /dev/null 2>&1"
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
        command "[ -f \"#{mrepo_config_file}\" ] && (umount #{wwwdir}/#{repo_name}*/disc* || true ) && /usr/bin/mrepo -gfu \"#{repo_name}\" > /dev/null 2>&1"
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
