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

# --[ Pkgs default directory structure ]--
default[:mrepo][:dir] = {
  :configdir => '/etc/mrepo.conf.d',
  :srcdir    => '/var/mrepo',
  :wwwdir    => '/var/www/mrepo',
  :lockdir   => '/var/run/mrepo',
}
default[:mrepo][:dir][:iso]      = "#{node[:mrepo][:dir][:srcdir]}/iso"
default[:mrepo][:dir][:key]      = "#{node[:mrepo][:wwwdir]}/RPM-GPG-KEY"
default[:mrepo][:dir][:cachedir] = node[:mrepo][:dir][:wwwdir]

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

# --[ Options de Configuration ]--
# [ SECTION MAIN ]
## Architecture to get
default[:mrepo][:conf][:main]['arch'] = node[:mrepo][:arch]

# The location of the ISO images and RPM files
default[:mrepo][:conf][:main]['srcdir'] = node[:mrepo][:dir][:srcdir]

## The location of the generated repositories
default[:mrepo][:conf][:main]['wwwdir'] = node[:mrepo][:dir][:wwwdir]

## The location of the dist config files
default[:mrepo][:conf][:main]['confdir'] = node[:mrepo][:dir][:configdir]

## The location of the cachedir (used by yum)
default[:mrepo][:conf][:main]['cachedir'] = node[:mrepo][:dir][:cachedir]

## The location of the lockdir
default[:mrepo][:conf][:main]['lockdir'] = node[:mrepo][:dir][:lockdir]

## The location of the logfile
default[:mrepo][:conf][:main]['logfile'] = node[:mrepo][:file][:log]

## Sent report to
default[:mrepo][:conf][:main]['mailto'] = 'root@localhost'

## SMTP servers
default[:mrepo][:conf][:main]['smtp_server'] = 'localhost'

## Default output (put this to yes if you want mrepo to be silent by default)
default[:mrepo][:conf][:main]['quiet'] = 'no'

## What repository metadata do you want to generate ? (Most generic: repomd)
default[:mrepo][:conf][:main]['metadata'] = 'repomd'

# [ Command line options ]
# --[ createrepo ]--
default[:mrepo][:conf][:main]['createrepocmd'] = '/usr/bin/createrepo'
# Add extra options to createrepocmd command
default[:mrepo][:conf][:main]['createrepo-options'] = '-p -d'

# --[ repoview ]--
default[:mrepo][:conf][:main]['repoviewcmd'] = '/usr/bin/repoview'
# Add extra options to repoview command
default[:mrepo][:conf][:main]['repoview-options'] = ''

# --[ lftp ]--
default[:mrepo][:conf][:main]['lftpcmd'] = '/usr/bin/lftp'
# Add extra options to lftp mirror command
default[:mrepo][:conf][:main]['lftp-mirror-options'] = '-c -P'
# Clean up packages that are not on the sending side ?
default[:mrepo][:conf][:main]['lftp-cleanup'] = 'yes'

# --[ rsync ]--
default[:mrepo][:conf][:main]['rsynccmd'] = '/usr/bin/rsync'
# Add extra options to rsync
default[:mrepo][:conf][:main]['rsync-options'] = '-rtHL --partial'
# Clean up packages that are not on the sending side ?
default[:mrepo][:conf][:main]['rsync-cleanup'] = 'yes'
