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

version = "#{node[:graphite][:version]}"

%w{ apache2 python-django python-django-tagging python-ldap python-memcache python-cairo python-rrdtool libapache2-mod-wsgi}.each do |webpacks|
  package "#{webpacks}" do
    action :install
  end
end

execute "download graphite-web" do
  cwd "/usr/src/"
  command "wget #{node[:graphite][:url]}/graphite-web-#{version}.tar.gz"
end

execute "untar graphite-web" do
  command "tar xzf graphite-web-#{version}.tar.gz"
  creates "/usr/src/graphite-web-#{version}"
  cwd "/usr/src"
end

execute "install graphite-web" do
  command "python setup.py install"
  cwd "/usr/src/graphite-web-#{version}"
end

directory "/etc/apache2/run" do
  owner node['apache']['user']
  group node['apache']['group']
end
  

directory "/opt/graphite/storage" do
  owner node['apache']['user']
  group node['apache']['group']
end

directory '/opt/graphite/storage/log' do
  owner node['apache']['user']
  group node['apache']['group']
end

%w{ webapp whisper }.each do |dir|
  directory "/opt/graphite/storage/log/#{dir}" do
    owner node['apache']['user']
    group node['apache']['group']
  end
end

file "/opt/graphite/storage/graphite.db" do
  owner node['apache']['user']
  group node['apache']['group']
  mode "644"
end

execute "copy vhost config" do
  command "cp examples/example-graphite-vhost.conf /etc/apache2/sites-available/graphite"
  cwd "/usr/src/graphite-web-#{version}"
end

execute "copy wsgi config" do
  command "cp  /opt/graphite/conf/graphite.wsgi.example  /opt/graphite/conf/graphite.wsgi"
  cwd "/opt/graphite/conf/"
end

execute "enable vhost graphite" do
  command "a2ensite graphite"
end

execute "disable vhost default" do
  command "a2dissite 000-default"
end

execute "copy local_settings" do
  command "cp local_settings.py.example local_settings.py"
  cwd "/opt/graphite/webapp/graphite"
end

cookbook_file "/usr/src/djangodb_answer" do
   source "djangodb_answer"
end

execute "append model.py" do
  command "cat /usr/src/djangodb_answer |tee -a /opt/graphite/webapp/graphite/account/models.py" 
  not_if "grep django.contrib.auth.management.create_superuser /opt/graphite/webapp/graphite/account/models.py"
end

bash "sync djangodb" do
   user "root"
   cwd "/opt/graphite/webapp/graphite/"
   code <<-EOH
     python manage.py syncdb
   EOH
end

execute "restart apache" do
  command "/etc/init.d/apache2 restart"
end
