### Install remi
yumrepo { 'remi':
  descr          => "Les RPM de remi pour Enterprise Linux ${::is_maj_version} - ${::architecture}",
  mirrorlist     => "http://rpms.famillecollet.com/enterprise/${::os_maj_version}/remi/mirror",
  enabled        => '1',
  gpgcheck       => '0',
}

yumrepo { 'remi-php55':
  descr          => "PHP 5.5 RPM repository for Enterprise Linux ${::is_maj_version} - ${::architecture}",
  mirrorlist     => "http://rpms.famillecollet.com/enterprise/${::os_maj_version}/php55/mirror",
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

### Install PHP-FPM with modules and NGINX
$php_packages = [ "php-fpm", "php-common", "php-opcache", "php-pecl-apcu", "php-cli", "php-pear", "php-pdo", "php-mysqlnd", "php-pgsql", "php-pecl-mongo", "php-pecl-sqlite", "php-pecl-memcache", "php-pecl-memcached", "php-gd", "php-mbstring", "php-mcrypt", "php-xml" ]

package { $php_packages: ensure => "installed", }
package { 'nginx': ensure => "installed", }

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
include '::mysql::server'

### Install WP
class { 'wordpress':
  install_dir => '/var/www/wordpress',
  wp_owner    => 'nginx',
  wp_group    => 'nginx',
  db_user     => 'tmtz',
  db_password => 'tmtz',
}
