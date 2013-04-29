#
# Cookbook Name::	mrepo
# Description::		Recipe to mirror any repository with 'mrepo'
# Recipe::				mirror.rb
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#
#

node[:mrepo][:repo].each do | repo_name, repo_tags |
  if ! repo_tags['arch'].nil?
    # --[ If 'arch' is array create a configuration for each arch ]--
    if repo_tags['arch'].is_a? Array
      repo_tags['arch'].each do |arch|
        template "#{node[:mrepo][:conf][:main]['confdir']}/#{repo_name}-#{arch}" do
          source 'mrepo.conf.erb'
          owner 'root'
          group 'root'
          mode  '0644'
          variables(
            :section => repo_name,
            :mrepo   => repo_args,
          )
        end
      end
    # --[ Otherwise use the string 'arch' ]--
    else
      template "#{node[:mrepo][:conf][:main]['confdir']}/#{repo_name}-#{repo_tags['arch']}" do
        source 'mrepo.conf.erb'
        owner 'root'
        group 'root'
        mode  '0644'
        variables(
          :section => repo_name,
          :mrepo   => repo_args,
        )
      end
    end
  end
end
