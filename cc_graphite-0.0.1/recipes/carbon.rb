#
# Cookbook Name:: cc_graphite
# Recipe:: default
#
# Copyright 2012, James Tran
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
#

package "python-twisted"
package "python-simplejson"

version = "#{node[:graphite][:version]}"

execute "download carbon" do
  cwd "/usr/src/"
  command "wget #{node[:graphite][:url]}/carbon-#{version}.tar.gz"
end

execute "untar carbon" do
  command "tar xzf carbon-#{version}.tar.gz"
  creates "/usr/src/carbon-#{version}"
  cwd "/usr/src"
end

execute "install carbon" do
  command "python setup.py install"
  cwd "/usr/src/carbon-#{version}"
end


execute "copy carbon conf" do
  command "cp carbon.conf.example carbon.conf"
  cwd "/opt/graphite/conf"
end

execute "copy storage-schema conf" do
  command "cp storage-schemas.conf.example storage-schemas.conf"
  cwd "/opt/graphite/conf"
end

execute "carbon: change graphite storage permissions to apache user" do
  command "chown -R #{node['apache']['user']}:#{node['apache']['group']} /opt/graphite/storage"
  only_if do
    f = File.stat("/opt/graphite/storage")
    f.uid == 0 and f.gid == 0
  end
end

directory "/opt/graphite/lib/twisted/plugins/" do
  owner node['apache']['user']
  group node['apache']['group']
end
