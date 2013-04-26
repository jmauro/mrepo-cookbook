#
# Cookbook Name:: mrepo
# Recipe:: default
# Author:: Jeremy MAURO <j.mauro@criteo.com>
# Description:: Recipe to setup mrepo
#
# Copyright 2013, Criteo
#
# All rights reserved - Do Not Redistribute
#
#

# --[ First of all: make sure epel is delcared]--
include_recipe 'yum::epel'

# --[ Install pkg ]--
node[:mrepo][:packages].each do |pkg|
  package pkg do
  end
end 

template '/etc/mrepo.conf' do
  source 'mrepo.conf.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  variables(
    :mrepo => node[:mrepo],
  )
end

# --[ Since 'mrepo' deploys one configuration file ]--
template '/etc/logrotate.d/mrepo' do
  source 'mrepo.logrotate.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  variables(
    :mrepo => node[:mrepo],
  )
end

# --[ Make sure directory are present ]--
node[:mrepo][:dir].each do |name, path|
  directory path do
    owner 'root'
    group 'root'
    mode  '0755'
    recursive true

    action :create
  end
end
