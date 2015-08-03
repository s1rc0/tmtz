### Install remi
yumrepo { 'remi':
  descr          => "Les RPM de remi pour Enterprise Linux 7 - ${::architecture}",
  mirrorlist     => "http://rpms.famillecollet.com/enterprise/7/remi/mirror",
  enabled        => '1',
  gpgcheck       => '0',
}

yumrepo { 'remi-php55':
  descr          => "PHP 5.5 RPM repository for Enterprise Linux 7 - ${::architecture}",
  mirrorlist     => "http://rpms.famillecollet.com/enterprise/7/php55/mirror",
  enabled        => '1',
  gpgcheck       => '0',
}

### Install epel repo
if $::operatingsystemmajrelease {
  $os_maj_release = $::operatingsystemmajrelease
} else {
  $os_versions    = split($::operatingsystemrelease, '[.]')
  $os_maj_release = $os_versions[0]
}

yumrepo { 'epel':
  mirrorlist     => "http://mirrors.fedoraproject.org/mirrorlist?repo=epel-${os_maj_release}&arch=\$basearch",
  baseurl        => 'absent',
  failovermethod => 'priority',
  enabled        => 1,
  gpgcheck       => 0,
  descr          => "Extra Packages for Enterprise Linux ${os_maj_release} - \$basearch",
}

### Install nginx repo
$osver = split($::operatingsystemrelease, '[.]')

yumrepo { 'nginx':
  descr    => 'Nginx official release packages',
  baseurl  => "http://nginx.org/packages/rhel/${osver[0]}/\$basearch/",
  enabled  => 1,
  gpgcheck => 0,
  priority => 1,
}

### Install mysql repo
yumrepo { 'mysql-connectors-community':
  descr    => 'MySQL Connectors Community',
  baseurl  => "http://repo.mysql.com/yum/mysql-connectors-community/el/7/\$basearch/",
  enabled  => 1,
  gpgcheck => 0,
}
yumrepo { 'mysql-tools-community':
  descr    => 'MySQL Tools Community',
  baseurl  => "http://repo.mysql.com/yum/mysql-tools-community/el/7/\$basearch/",
  enabled  => 1,
  gpgcheck => 0,
}
yumrepo { 'mysql56-community':
  descr    => 'MySQL 5.6 Community Server',
  baseurl  => "http://repo.mysql.com/yum/mysql-5.6-community/el/7/\$basearch/",
  enabled  => 1,
  gpgcheck => 0,
}

### Install PHP-FPM with modules and NGINX
$php_packages = [ "php-fpm", "php-common", "php-cli", "php-pear", "php-pdo", "php-mysqlnd", "php-gd", "php-mbstring", "php-mcrypt", "php-xml" ]

package { $php_packages: ensure => "installed", require => [ Yumrepo['remi'], Yumrepo['remi-php55'] ], }
package { 'nginx': ensure => "installed", require => Yumrepo['nginx'], }

### Run and setting autoload nginx and php-fpm
service { 'nginx':
  ensure     => running,
  enable     => true,
  hasrestart => true,
  require    => File['/etc/nginx/conf.d/default.conf'],
  restart    => 'systemctl reload nginx'
}
file { '/etc/nginx/conf.d/default.conf':
  ensure  => present,
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  content => file('/root/tmtz/default.conf'),
  notify  => Service['nginx'],
  require => Package['nginx'],
}
service { 'php-fpm':
  ensure     => running,
  enable     => true,
  hasrestart => true,
  restart    => 'systemctl reload php-fpm'
}

### Install mysql

class { 'mysql::server':
#  client_package_name => 'mysql',
  package_name => 'mysql-community-server',
  service_name => 'mysqld',
  require => [ Yumrepo['mysql-connectors-community'], Yumrepo['mysql-tools-community'], Yumrepo['mysql56-community'] ],
}
#include '::mysql::server'

### Install WP
class { 'wordpress':
  install_dir => '/var/www/wordpress',
  wp_owner    => 'nginx',
  wp_group    => 'nginx',
  db_user     => 'tmtz',
  db_password => 'tmtz',
}

