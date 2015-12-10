#
# Cookbook Name:: mrepo
# Spec:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'mrepo::default' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      stub_command('test -r /dev/loop255').and_return(0)
      expect { chef_run }.to_not raise_error
    end
  end
end
