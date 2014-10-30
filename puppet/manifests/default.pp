$ar_databases = ['vagrant']
$as_vagrant   = 'sudo -u vagrant -H bash -l -c'
$home         = '/home/vagrant'

Exec {
  path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin']
}

# --- Preinstall Stage ---------------------------------------------------------

stage { 'preinstall':
  before => Stage['main']
}

class apt_get_update {
  exec { 'apt-get -y update':
    unless => "test -e ${home}/.rvm"
  }
}
class { 'apt_get_update':
  stage => preinstall
}

class apt_get_nsf_common {
  exec { 'apt-get install nfs-common portmap':
  }
}
class { 'apt_get_nsf_common':
  stage => preinstall
}

# --- SQLite -------------------------------------------------------------------

package { ['sqlite3', 'libsqlite3-dev']:
  ensure => installed;
}

# --- MySQL --------------------------------------------------------------------

class install_mysql {
  class { 'mysql': }

  class { 'mysql::server':
    config_hash => { 'root_password' => '' }
  }

  database { $ar_databases:
    ensure  => present,
    charset => 'utf8',
    require => Class['mysql::server']
  }

  database_user { 'rails@localhost':
    ensure  => present,
    require => Class['mysql::server']
  }

  database_grant { ['rails@localhost/activerecord_unittest', 'rails@localhost/activerecord_unittest2']:
    privileges => ['all'],
    require    => Database_user['rails@localhost']
  }

  package { 'libmysqlclient15-dev':
    ensure => installed
  }
}
class { 'install_mysql': }

# Imagick
class { 'imagemagick': }

# --- PostgreSQL ---------------------------------------------------------------
# class install_postgres {
  # Install PostgreSQL 9.3 server from the PGDG repository
  class {'postgresql::globals':
    version             => '9.3',
    manage_package_repo => true,
    encoding            => 'UTF8',
    locale              => 'en_US.UTF-8',
  }->
  class { 'postgresql::server':
    ensure           => 'present',
    listen_addresses => '*',
    manage_firewall  => true,
  }

  # workaround for https://tickets.puppetlabs.com/browse/PUP-1191
  # when PostgreSQL is installed with SQL_ASCII encoding instead of UTF8
  # OR, Puppet overrides locale and encoding settings on Debian/Ubuntu
  exec { 'utf8 postgres':
    command => 'pg_dropcluster --stop 9.3 main ; pg_createcluster --start --locale en_US.UTF-8 9.3 main',
    unless  => 'sudo -u postgres psql -t -c "\l" | grep template1 | grep -q UTF',
    require => Class['postgresql::server'],
    path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  }

  exec { "/usr/bin/psql -d template1 -c 'CREATE EXTENSION hstore;'":
    user   => "postgres",
    require => Class['postgresql::server'],
    unless => "/usr/bin/psql -d template1 -c '\\dx' | grep hstore",
  }

  # Create user for vagrant
  postgresql::server::role { 'vagrant':
    createdb      => true,
    password_hash => postgresql_password('vagrant', 'vagrant'),
  }

  # Create database
  postgresql::server::db { 'vagrant':
    user     => 'vagrant',
    password => postgresql_password('vagrant', 'vagrant'),
    encoding => 'UTF8',
    locale   => 'en_US.UTF-8',
  }

  # Install contrib modules
  class { 'postgresql::server::contrib':
    package_ensure => 'present',
  }

  package { ['libpq-dev']:
    ensure => installed;
  }

# }

# class { 'install_postgres': }

# --- Memcached ----------------------------------------------------------------

class { 'memcached': }


# --- Packages -----------------------------------------------------------------

package { 'curl':
  ensure => installed
}

package { 'build-essential':
  ensure => installed
}

package { 'git-core':
  ensure => installed
}

# Nokogiri dependencies.
package { ['libxml2', 'libxml2-dev', 'libxslt1-dev']:
  ensure => installed
}

# ExecJS runtime.
package { 'nodejs':
  ensure => installed
}

# --- OHMYZSH ----------------------------------------------------------------

class { 'zsh': }

# --- Ruby -------------------------------------------------------------------

exec { 'install_rvm':
  command => "${as_vagrant} 'curl -L https://get.rvm.io | bash -s stable'",
  creates => "${home}/.rvm",
  require => Package['curl']
}

exec { 'install_ruby':
  # We run the rvm executable directly because the shell function assumes an
  # interactive environment, in particular to display messages or ask questions.
  # The rvm executable is more suitable for automated installs.
  #
  # Thanks to @mpapis for this tip.
  # command => "${as_vagrant} '${home}/.rvm/bin/rvm install 2.0.0 --latest-binary --autolibs=enabled && rvm --fuzzy alias create default 2.0.0'",
  command => "${as_vagrant} '${home}/.rvm/bin/rvm install 2.0.0 --autolibs=enabled && rvm --fuzzy alias create default 2.0.0'",
  creates => "${home}/.rvm/bin/ruby",
  require => Exec['install_rvm']
}

exec { "${as_vagrant} 'gem install bundler --no-rdoc --no-ri'":
  creates => "${home}/.rvm/bin/bundle",
  require => Exec['install_ruby']
}

# file {
#   "/home/vagrant/.bash_profile":
#   source => "/vagrant/puppet/files/bash_profile",
#   owner => "vagrant", group => "vagrant", mode => 0664;
# }


# --- Install Redis ----------------------------------------------------------
class apt_get_redis {
  exec { 'apt-get install redis-server':
  }
}
class { 'apt_get_redis':
}

# --- Install MongoDB --------------------------------------------------------
package { 'mongodb':
  ensure => present,
}

service { 'mongodb':
  ensure  => running,
  require => Package['mongodb'],
}

exec { 'allow remote mongo connections':
  command => "/usr/bin/sudo sed -i 's/bind_ip = 127.0.0.1/bind_ip = 0.0.0.0/g' /etc/mongodb.conf",
  notify  => Service['mongodb'],
  onlyif  => '/bin/grep -qx  "bind_ip = 127.0.0.1" /etc/mongodb.conf',
}
