#
# Cookbook Name::	test-mrepo
# Description::		Test mrepo
# Recipe::				mirror
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#
#

centos_url = 'http://fr2.rpmfind.net/linux/centos'
node.default[:mrepo][:repo] = {
  'os-CentOS-6-x86_64' => {
    'arch'          => 'x86_64',
    'update'        => 'daily',
    'metadata'      => 'repomd repoview',
    'action'        => 'create',
    'release'       => 6,
    'name'          => 'Repository CentOS $release minimal for Deploying servers',
    'iso'           => 'CentOS-*-x86_64-minimal.iso',
    'iso_sha256sum' => "#{centos_url}/6/isos/x86_64/sha256sum.txt",
    'iso_url'       => ["#{centos_url}/6/isos/x86_64/CentOS-6.5-x86_64-minimal.iso"],
    'extras'        => "#{centos_url}/$release/extras/$arch/Packages/",
  },
}

include_recipe 'mrepo::mirror'

execute '/usr/bin/mrepo -guvvf os-CentOS-6-x86_64'
