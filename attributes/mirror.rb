#
# Cookbook Name::	mrepo
# Description::		Default attribut to mirror repositories
# Recipe::				mirror.rb
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#

# --[ Default option ]--
default[:mrepo][:mirror]['arch']     = node[:mrepo][:arch]
default[:mrepo][:mirror]['update']   = 'daily'
default[:mrepo][:mirror]['action']   = 'create'
default[:mrepo][:mirror]['metadata'] = 'repomd'
default[:mrepo][:mirror]['timeout']  = '3600'

# --[ Options set ]--
default[:mrepo][:mirror][:options_set] = {
  :action => [ 'create', 'delete' ],
  :update => [ 'now', 'weekly', 'nightly', 'never', 'daily' ],
}

## --[ Repository to mirror definition ]--
#default[:mrepo][:repo] = {
#  'epel-CentOS-6' => {
#    # --[ Generic options linked to the repo ]--
#    'name'     => 'Repository Extra Packages for Enterprise Linux 6',
#    'release'  => '6',
#    'arch'     => node[:mrepo][:mirror]['arch'],
#    'update'   => node[:mrepo][:mirror]['update'],
#    'metadata' => node[:mrepo][:mirror]['metadata'],
#    'action'   => node[:mrepo][:mirror]['action'],
#    'key_url'  => 'http://fr2.rpmfind.net/linux/epel/RPM-GPG-KEY-EPEL-6',
#    # --[ Repository definition ]--
#    'epel'     => 'rsync://mirror.i3d.net/fedora-epel/6/$arch',
#  },
#}
