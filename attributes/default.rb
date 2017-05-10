#
# Cookbook Name::	mrepo
# Description::		Default attribut
# Recipe::				default
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#
#

# --[ Packages definition ]--
default['mrepo']['packages'] = %w(mrepo rsync lftp createrepo hardlink repoview fuse curl wget)

# Only to handle Fedora Core < 3 and RedHat Enterprise Linux < 4.
default['mrepo']['packages'] << 'yum-arch' if node['platform_version'].to_i < 7

# --[ Pkgs default directory structure ]--
default['mrepo']['dir'] = {
  configdir: '/etc/mrepo.conf.d',
  srcdir:    '/var/mrepo',
  wwwdir:    '/var/www/mrepo',
  lockdir:   '/var/run/mrepo',
  cachedir:  '/var/cache/mrepo',
}
default['mrepo']['dir']['iso']      = "#{node['mrepo']['dir']['srcdir']}/iso"
default['mrepo']['dir']['key']      = "#{node['mrepo']['dir']['wwwdir']}/RPM-GPG-KEY"

# --[ File declaration ]--
default['mrepo']['file']['log']       = '/var/log/mrepo.log'
default['mrepo']['file']['conf']      = '/etc/mrepo.conf'
default['mrepo']['file']['logrotate'] = '/etc/logrotate.d/mrepo'

# --[ Repo to create ]--
case node['platform_family']
when 'rhel'
  default['mrepo']['metadata'] = 'repomd yum'
when 'debian'
  default['mrepo']['metadata'] = 'repomd apt'
end

# --[ CPU architecture ]--
default['mrepo']['arch'] = node['machine'] || 'x86_64'
