#
# Cookbook Name::	mrepo
# Description::		Default attribut
# Recipe::				default
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#
#

# --[ Packages definition ]--
default[:mrepo][:packages] = [ 'mrepo', 'rsync', 'lftp', 'createrepo', 'hardlink', 'repoview', 'yum-arch', 'fuse', 'curl', ]

# --[ Pkgs default directory structure ]--
default[:mrepo][:dir] = {
  :configdir => '/etc/mrepo.conf.d',
  :srcdir    => '/var/mrepo',
  :wwwdir    => '/var/www/mrepo',
  :lockdir   => '/var/run/mrepo',
  :cachedir  => '/var/cache/mrepo',
}
default[:mrepo][:dir][:iso]      = "#{node[:mrepo][:dir][:srcdir]}/iso"
default[:mrepo][:dir][:key]      = "#{node[:mrepo][:dir][:wwwdir]}/RPM-GPG-KEY"

# --[ File declaration ]--
default[:mrepo][:file][:log]       = '/var/log/mrepo.log'
default[:mrepo][:file][:conf]      = '/etc/mrepo.conf'
default[:mrepo][:file][:logrotate] = '/etc/logrotate.d/mrepo'

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
