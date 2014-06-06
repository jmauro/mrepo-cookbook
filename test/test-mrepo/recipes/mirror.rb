#
# Cookbook Name::	test-mrepo
# Description::		Test mrepo
# Recipe::				mirror
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#
#

node.default[:mrepo][:repo] = {
  'os-CentOS-6-x86_64' => {
    'arch'       => 'x86_64',
    'update'     => 'daily',
    'metadata'   => 'repomd repoview',
    'action'     => 'create',
    'release'    => 6,
    'name'       => 'Repository CentOS $release minimal for Deploying servers',
    'iso'        => 'CentOS-*-x86_64-minimal.iso',
    'iso_md5sum' => 'http://ftp.free.fr/mirrors/ftp.centos.org/6/isos/x86_64/md5sum.txt',
    'iso_url'    => ['http://ftp.free.fr/mirrors/ftp.centos.org/6/isos/x86_64/CentOS-6.5-x86_64-minimal.iso'],
    'centosplus' => 'http://ftp.free.fr/mirrors/ftp.centos.org/6/centosplus/x86_64/Packages',
  },
}


include_recipe 'mrepo::mirror'

execute '/usr/bin/mrepo -guvvf os-CentOS-6-x86_64'
