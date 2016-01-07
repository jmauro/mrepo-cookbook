source "https://supermarket.chef.io"


metadata

# Test recipes
cookbook 'test-mrepo', :path => './test/test-mrepo'

def ck(name)
  cookbook name, git: "https://gitlab.criteois.com/chef-cookbooks/#{name}.git"
end

%w(
  criteo-ipam
  criteo-location
  dmi
  hp
  lldp
  network
  yum-criteo
).each {|name| ck(name) }
