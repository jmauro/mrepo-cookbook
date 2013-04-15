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
    action :install
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

template '/etc/logrotate.d/mrepo' do
  source 'mrepo.logrotate.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  variables(
    :mrepo => node[:mrepo],
  )
end

# --[ Make directory are present ]--
dir_create = [
  "#{node[:mrepo][:keydir]}",
  "#{node[:mrepo][:srcdir]}",
  "#{node[:mrepo][:wwwdir]}",
  "#{node[:mrepo][:lockdir]}",
  "#{node[:mrepo][:cachedir]}",
  "#{node[:mrepo][:config_dir]}",
  ]
dir_create.each do |dir|
  directory dir do
    owner 'root'
    group 'root'
    mode  '0755'
    recursive true

    action :create
  end
end
