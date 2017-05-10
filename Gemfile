source 'https://rubygems.org'

# Common gems for development and testing:
def gitlab(name)
  gem name, git: "https://gitlab.criteois.com/ruby-gems/#{name}.git"
end
gitlab 'goag'
gem 'kitchen-transport-speedy'
group :ec2 do
  gem 'dotenv'
  gem 'kitchen-ec2', git: 'https://github.com/criteo-forks/kitchen-ec2.git', branch: 'criteo'
  gem 'test-kitchen'
  gem 'winrm', '>= 1.6'
  gem 'winrm-fs', '>= 0.3'
end

# Other gems should go after this comment
gem 'rubocop', '=0.47.1'
