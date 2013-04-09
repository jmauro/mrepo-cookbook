#
# Cookbook Name::	mrepo
# Description::		Default attribut
# Recipe::				default
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#
#

# --[ Packages definition ]--
default[:mrepo][:packages] = [ 'mrepo', 'rsync', 'lftp', 'createrepo', 'hardlink', 'repoview', 'yum-arch' ]

# --[ Configuration files and directory ]--
default[:mrepo][:config_dir]  = '/etc/mrepo.conf.d'
default[:mrepo][:config_file] = '/etc/mrepo.conf'

# --[ Pkgs default directory structure ]--
default[:mrepo][:srcdir]   = '/var/mrepo'
default[:mrepo][:wwwdir]   = '/var/www/mrepo'
default[:mrepo][:lockdir]  = '/var/run/mrepo'
default[:mrepo][:cachedir] = '/var/cache/mrepo'
default[:mrepo][:logfile]  = '/var/log/mrepo.log'

# --[ Repo to create ]--
if platform_family?('rhel')
  default[:mrepo][:metadata] = 'repomd yum'
elsif platform_family?('debian')
  default[:mrepo][:metadata] = 'repomd apt'
end

# --[ CPU architecture ]--
default[:mrepo][:arch] = 'x86_64'

# --[ Report ]--
default[:mrepo][:mailto]      = 'root@localhost'
default[:mrepo][:smtp_server] = 'localhost'

