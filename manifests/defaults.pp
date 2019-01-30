# ----------
# Configure service startup defaults
# factered out of dhcp class due to dhcp6 requirements
# ----------
class dhcp::defaults (
  Optional[Array[String]] $dhcp_interfaces = undef,
  Optional[Array[String]] $dhcp6_interfaces = undef,
) {

  include ::dhcp::params

  $dhcp_dir = $::dhcp::params::dhcp_dir
  $packagename = $::dhcp::params::packagename
  $servicename = $::dhcp::params::servicename
  $servicename6 = $::dhcp::params::servicename6

  $ipv4 = $dhcp_interfaces ? {
    undef   => false,
    default => true,
  }

  $ipv6 = $dhcp6_interfaces ? {
    undef   => false,
    default => true,
  }

  if $ipv4 and $ipv6 {
    if $servicename != $servicename6 {
      $notify = [Service[$servicename],Service[$servicename6]]
    }
    else {
      $notify = Service[$servicename]
    }
  }
  elsif($ipv4) {
    $notify = Service[$servicename]
  }
  elsif($ipv6) {
    $notify = Service[$servicename6]
  }
  else {
    fail( "You must define either the dhcp interfaces or the dhcp6 interfaces")
  }

  # Only debian and ubuntu have this style of defaults for startup.
  case $::osfamily {
    'Debian': {
      file { '/etc/default/isc-dhcp-server':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        before  => Package[$packagename],
        notify  => $notify,
        content => template('dhcp/debian/default_isc-dhcp-server'),
      }
    }
    'RedHat': {
      if versioncmp($::operatingsystemmajrelease, '7') >= 0 {
        include ::systemd
        if $ipv4 {
          systemd::dropin_file { 'interfaces.conf':
            unit    => 'dhcpd.service',
            content => template('dhcp/redhat/systemd-dropin.conf.erb'),
          }
        }
        if $ipv6 {
          systemd::dropin_file { 'interfaces6.conf':
            unit    => 'dhcpd6.service',
            content => template('dhcp/redhat/systemd-dropin6.conf.erb'),
          }
        }
      } else {
        file { '/etc/sysconfig/dhcpd':
          ensure  => file,
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          before  => Package[$packagename],
          notify  => $notify,
          content => template('dhcp/redhat/sysconfig-dhcpd'),
        }
      }
    }
    /^(FreeBSD|DragonFly)$/: {
      # I suspect we need an interfaces6_line but do not know
      $interfaces_line = join($dhcp_interfaces, ' ')
      augeas { 'set listen interfaces':
        context => '/files/etc/rc.conf',
        changes => "set dhcpd_ifaces '\"${interfaces_line}\"'",
        before  => Package[$packagename],
        notify  => $notify,
      }
    }
    default: {
    }
  }

}
