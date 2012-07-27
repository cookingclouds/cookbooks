#
# Cookbook Name:: cc_cgit
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

package "build-essential"
package "autoconf"
package "automake"
package "libtool"
package "libfcgi-dev"
package "spawn-fcgi"
package "libssl-dev"
package "git-core"
package "nginx"

directory "/opt/repositories" do
  owner "www-data"
  group "www-data"
  action :create
  mode "0777"
end

bash "Install fcgiwrap" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    git clone git://github.com/gnosek/fcgiwrap.git
    cd fcgiwrap
    autoreconf -i
    ./configure
    make
    make install
    cp fcgiwrap /usr/local/bin/
  EOH
  not_if "test -e /usr/local/bin/fcgiwrap"
end

template "/tmp/cgit.conf" do
  source "tmp/cgit.conf.erb"
end

bash "Install cgit" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    git clone git://hjemli.net/pub/git/cgit
    cd cgit
    cp /tmp/cgit.conf .
    git submodule init
    git submodule update
    make
    make install
  EOH
end

template "/usr/local/bin/cgit-fcgiwrap" do
  source "usr/local/bin/cgit-fcgiwrap.erb"
  owner "root"
  mode "755"
end

template "/etc/init.d/cgit-fastcgi" do
  source "etc/init.d/cgit-fastcgi.erb"
  owner "root"
  mode "755"
end

template "/etc/cgitrc" do
  source "etc/cgitrc.erb"
  owner "root"
  mode "0755"
end

service "cgit-fastcgi" do
  action [ :enable ]
end

service "nginx" do
  supports :reload => true
  action :nothing
end

bash "Disable NGINX default site" do
  code <<-EOH
    rm /etc/nginx/sites-enabled/default
  EOH
  only_if "test -e /etc/nginx/sites-enabled/default"
end

template "/etc/nginx/sites-available/cgit" do
  owner "root"
  source "etc/nginx/sites-available/cgit.erb"
end

bash "Enable NGINX cgit site" do
  user "root"
  code <<-EOH
    ln -s /etc/nginx/sites-available/cgit /etc/nginx/sites-enabled/cgit
  EOH
  notifies :reload, "service[nginx]"
  not_if "test -e /etc/nginx/sites-enabled/cgit"
end

