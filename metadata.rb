name             'mrepo'
maintainer       'Criteo'
maintainer_email 'j.mauro@criteo.com'
license          'All rights reserved'
description      'Installs/Configures mrepo'
long_description 'Installs/Configures mrepo'
issues_url       'https://gitlab.criteois.com/chef-cookbooks/mrepo'
source_url       'https://gitlab.criteois.com/chef-cookbooks/mrepo'
require          'cookbook-release'
# to see current version: bundle exec rake release:version
version          ::CookbookRelease::Release.current_version(__FILE__)
supports         'centos'
depends          'yum-epel'
