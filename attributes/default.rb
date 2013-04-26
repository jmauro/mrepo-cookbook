#
# Cookbook Name::	mrepo
# Description::		Default attribut
# Recipe::				default
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#
#

# --[ Packages definition ]--
default[:mrepo][:packages] = [ 'mrepo', 'rsync', 'lftp', 'createrepo', 'hardlink', 'repoview', 'yum-arch', 'fuse', ]

# --[ Configuration files and directory ]--
default[:mrepo][:config_dir]  = '/etc/mrepo.conf.d'
default[:mrepo][:config_file] = '/etc/mrepo.conf'

# --[ Pkgs default directory structure ]--
default[:mrepo][:dir] = {
  :src      => '/var/mrepo',
  :www      => '/var/www/mrepo',
  :lock     => '/var/run/mrepo',
  :cachedir => '/var/www/mrepo',
  :iso      => "#{node[:mrepo][:srcdir]}/iso",
  :key      => "#{node[:mrepo][:wwwdir]}/RPM-GPG-KEY"
}

default[:mrepo][:logfile]  = '/var/log/mrepo.log'

# --[ Repo to create ]--
case node[:platform_family]
when 'rhel'
  default[:mrepo][:metadata] = 'repomd yum'
when 'debian'
  default[:mrepo][:metadata] = 'repomd apt'
end

# --[ CPU architecture ]--
if node[:machine]
  default[:mrepo][:arch] = node[:machine]
else
  default[:mrepo][:arch] = 'x86_64'
end

# --[ Report ]--
default[:mrepo][:mailto]      = 'root@localhost'
default[:mrepo][:smtp_server] = 'localhost'
