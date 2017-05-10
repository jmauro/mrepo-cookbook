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
include_recipe 'yum-epel'

# --[ Install pkg ]--
node[:mrepo][:packages].each do |pkg|
  package pkg do
  end
end

template node['mrepo']['file']['conf'] do
  source 'mrepo.conf.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  variables(
    section: 'main',
    mrepo:   node['mrepo']['conf']['main']
  )
end

# --[ Since 'mrepo' deploys one configuration file ]--
template node['mrepo']['file']['logrotate'] do
  source 'mrepo.logrotate.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  variables(
    mrepo: node['mrepo']
  )
end

# --[ Make sure directory are present                          ]--
# --[ NOTE:  "sort" is not needed since "recursive" is present ]--
node['mrepo']['dir'].sort { |a, b| a[1] <=> b[1] }.each do |_name, path|
  directory path do
    owner 'root'
    group 'root'
    mode  '0755'
    recursive true

    action :create
  end
end

# --[ Make sure loopdevice exist ]--
if node['platform_version'].to_i < 7
  execute 'Checking loop device number' do
    path ['/sbin', '/usr/sbin', '/bin', '/usr/bin']
    # --[ Create 256 loop devices ]--
    command 'MAKEDEV -v /dev/loop'
    not_if 'test -r /dev/loop255'

    action :run
  end
end
