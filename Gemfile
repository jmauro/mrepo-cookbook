source 'https://rubygems.org'

# Common gems for development and testing:
def gitlab(name)
  gem name, git: "https://gitlab.criteois.com/ruby-gems/#{name}.git"
end
gitlab 'goag'
gem 'kitchen-transport-speedy'
group :ec2 do
  gem 'test-kitchen'
  gem 'kitchen-ec2', git: 'https://github.com/criteo-forks/kitchen-ec2.git', branch: 'criteo'
  gem 'winrm',       '>= 1.6'
  gem 'winrm-fs',    '>= 0.3'
  gem 'dotenv'
end

# Other gems should go after this comment
gem 'rubocop', '=0.47.1'
