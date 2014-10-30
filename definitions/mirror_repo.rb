#
# Cookbook Name::	mrepo
# Description::		Definition to add remote repository to mrepo
# Recipe::				mirror_repo.rb
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#

# Example of use:
# mirror_repo 'CentOS-6-x86_64' do
#   repo  ({
#     description 'Repository CentOS 5.6 32 bit'
#     release   '5.6'
#     arch      'i386'
#     metadata  [ 'repomd' , 'yum' ]
#     action    'create'
#     update    'nightly'
#     addons      => 'rsync://mirrors.kernel.org/centos/$release/addons/$arch/',
#     centosplus  => 'rsync://mirrors.kernel.org/centos/$release/centosplus/$arch/',
#     updates     => 'rsync://mirrors.kernel.org/centos/$release/updates/$arch/',
#   })
#   cookbook 'mrepo'
# end

define :mirror_repo,
  :action   => 'create',
  :cookbook => 'mrepo',
  :repo     => nil do

    mrepo_binary = '/usr/bin/mrepo'
    mrepo_binary = "/usr/bin/mrepo -c #{node[:mrepo][:file][:conf]}" if node[:mrepo][:file][:conf] != '/etc/mrepo.conf'
    include_recipe 'mrepo'

    # --[ Get the parameters ]--
    repo_name         = params[:name]
    repo_tags         = params[:repo]
    gentimeout        = node[:mrepo][:mirror]['timeout'].to_i
    isodir            = node[:mrepo][:dir][:iso]
    keydir            = node[:mrepo][:dir][:key]
    srcdir            = node[:mrepo][:conf][:main]['srcdir']
    wwwdir            = node[:mrepo][:conf][:main]['wwwdir']
    confdir           = node[:mrepo][:conf][:main]['confdir']
    mrepo_config_file = "#{confdir}/#{repo_name}.conf"

    # --[ Check arguments ]--
    cron_hour     = node[:mrepo][:mirror]['cron_hour']
    minute_random = (node[:mrepo][:mirror]['minute_ip'] + repo_name.sum) % 60
    array_action  = [repo_tags['action']]
    array_update  = [repo_tags['update']]
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
    # Note: If delete no arguments needed
    if repo_tags['action'] != 'delete'
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
        if params[:cookbook]
          cookbook params[:cookbook]
        end
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
        key_name = repo_tags['key_name'] if repo_tags['key_name']
        remote_file "#{keydir}/#{key_name}" do
          owner 'root'
          group 'root'
          mode '0644'
          source key_url
          backup false
        end
      end

      unless repo_tags['iso_url'].nil?
        iso_url = repo_tags['iso_url']

        iso_url.each do | iso_dvd |
          iso_name = /.*\/(.*)$/.match(iso_dvd)[1]
          # --[ Gettin md5sum file if given by user ]--
          remote_file "#{isodir}/#{iso_name}.md5sum" do
            owner 'root'
            group 'root'
            mode '0644'
            source repo_tags['iso_md5sum']
            not_if { repo_tags['iso_md5sum'].nil? }
            backup false
          end

          execute "Getting iso: #{iso_name}" do
            path ['/bin', '/usr/bin']
            # --[ Make sure iso not mounted when downloading it ]--
            command "(losetup --show -f #{isodir}/#{iso_name} >/dev/null 2>&1 && umount #{isodir}/#{iso_name} 2>/dev/null >&2 || true) && curl -s -S #{iso_dvd} -o #{isodir}/#{iso_name}"
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
        path ['/usr/bin', '/bin']
        if repo_tags['update'] =~ /(?i-mx:now|once)/
          # --[ Update repo at least once ]--
          command "#{mrepo_binary} -gfu \"#{repo_name}\""
        else
          command "#{mrepo_binary} -gf \"#{repo_name}\""
        end
        cwd srcdir
        user 'root'
        group 'root'
        timeout gentimeout

        action :nothing
        notifies :write, "log[Generating #{repo_name}]"
      end

      if repo_tags['update'] =~ /(?i-mx:once)/
        # --[ Removing Crons ]--
        cron "Nightly synchronize repo #{repo_name}" do

          action :delete
        end

        cron "Weekly synchronize repo #{repo_name}" do

          action :delete
        end

      elsif repo_tags['update'] =~ /(?i-mx:nightly|daily|now)/
        # --[ Update repo is done every night ]--
        log "Setting nightly cron #{repo_name}" do
          message ">>> [:mirror_repo] Setting nightly cron for '#{repo_name}'"
          level :info

          action :nothing
        end

        cron "Nightly synchronize repo #{repo_name}" do
          hour cron_hour
          minute minute_random
          path '/bin:/usr/bin'
          command "[ -f \"#{mrepo_config_file}\" ] && (umount #{wwwdir}/#{repo_name}*/disc* 2> /dev/null || true ) && #{mrepo_binary} -gfu \"#{repo_name}\" > /dev/null 2>&1"
          user 'root'
          home srcdir
          shell '/bin/bash'

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
          hour cron_hour
          minute minute_random
          path "/bin:/usr/bin"
          command "[ -f \"#{mrepo_config_file}\" ] && (umount #{wwwdir}/#{repo_name}*/disc* || true ) && #{mrepo_binary} -gfu \"#{repo_name}\" > /dev/null 2>&1"
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
        command "umount #{wwwdir}/#{repo_name}*/disc* || true"
        user 'root'
        group 'root'
        only_if "/bin/mount | /bin/grep #{wwwdir}/#{repo_name} | grep disc"

        notifies :write, "log[Unmounting iso #{repo_name}]"
      end

      # --[ Directory ]--
      log "Removing dir #{repo_name}" do
        message ">>> [:mirror_repo] Removing directory for repo '#{repo_name}'"
        level :info

        action :nothing
      end
      dir_to_remove = %W(#{wwwdir}/#{repo_name} #{srcdir}/#{repo_name})
      dir_to_remove.each do |dir|
        directory dir do
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
