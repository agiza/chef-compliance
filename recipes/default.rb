#
# Cookbook Name:: chef-compliance
# Recipe:: default
#
# Copyright 2016 Skyscape Cloud Services
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

download = node['compliance'][node['compliance']['version']][node['platform_family']][node['platform_version'].to_i]

local_file = download['url'].match(/(chef-compliance.*)\//)[1]

remote_file "#{Chef::Config[:file_cache_path]}/#{local_file}" do
  owner 'root'
  group 'root'
  mode '0644'
  source download['url']
end

package 'chef-compliance' do
  action :install
  source "#{Chef::Config[:file_cache_path]}/#{local_file}"
end

