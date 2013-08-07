#
# Cookbook Name::	mrepo
# Description::		Default attribut
# Recipe::				conf.rb
# Author::        Jeremy MAURO (j.mauro@criteo.com)
#
#
#

# [ SECTION MAIN ]
default[:mrepo][:conf][:main] = {
  ## Architecture to get
  'arch' => node[:mrepo][:arch],

  # The location of the ISO images and RPM files
  'srcdir' => node[:mrepo][:dir][:srcdir],

  ## The location of the generated repositories
  'wwwdir' => node[:mrepo][:dir][:wwwdir],

  ## The location of the dist config files
  'confdir' => node[:mrepo][:dir][:configdir],

  ## The location of the cachedir (used by yum)
  'cachedir' => node[:mrepo][:dir][:cachedir],

  ## The location of the lockdir
  'lockdir' => node[:mrepo][:dir][:lockdir],

  ## The location of the logfile
  'logfile' => node[:mrepo][:file][:log],

  ## Sent report to
  'mailto' => 'root@localhost',

  ## SMTP servers
  'smtp_server' => 'localhost',

  ## Default output (put this to yes if you want mrepo to be silent by default)
  'quiet' => 'no',

  ## What repository metadata do you want to generate ? (Most generic: repomd)
  'metadata' => 'repomd',

  # [ Command line options ]
  # --[ createrepo ]--
  'createrepocmd' => '/usr/bin/createrepo',
  # Add extra options to createrepocmd command
  'createrepo-options' => '-p -d',

  # --[ repoview ]--
  'repoviewcmd' => '/usr/bin/repoview',
  # Add extra options to repoview command
  'repoview-options' => '',

  # --[ lftp ]--
  'lftpcmd' => '/usr/bin/lftp',
  # Set lftp options
  'lftp-commands' => '',
  # Add extra options to lftp mirror command
  'lftp-mirror-options' => '-c -P',
  # Clean up packages that are not on the sending side ?
  'lftp-cleanup' => 'yes',

  # --[ rsync ]--
  'rsynccmd' => '/usr/bin/rsync',
  # Add extra options to rsync
  'rsync-options' => '-rtHL --partial',
  # Clean up packages that are not on the sending side ?
  'rsync-cleanup' => 'yes',
}
