#
# Cookbook Name::	mrepo
# Description::		Default attribut to mirror repositories
# Recipe::				mirror.rb
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#
#

# --[ Repository to mirror definition ]--
default[:mrepo][:repo] {
  'epel-CentOS-6' => {
    'tete' => '',
  },
  'epel-CentOS-5' => {
    'description' => 'test',
  },
}
