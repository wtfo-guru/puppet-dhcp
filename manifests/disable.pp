# ----------
# Remove and Disable the DHCP server
# ----------
class dhcp::disable (
  Boolean $ipv4 = true,
  Boolean $ipv6 = true,
){

  if $ipv4 or $ipv6 {

    include ::dhcp::params

    $packagename = $::dhcp::params::packagename
    $servicename = $::dhcp::params::servicename
    $servicename6 = $::dhcp::params::servicename6

    if $ipv4 and $ipv6 {
      package { $packagename:
        ensure => absent,
      }
      $services = unique([$servicename, $servicename6])
      $require = Package[$packagename]
    }
    elsif $ipv4 {
      $services = $servicename == $servicename6 ? {
        true    => undef,
        default => $servicename,
      }
      $require = undef
    }
    else { # it has to be ipv6
      $services = $servicename == $servicename6 ? {
        true    => undef,
        default => $servicename6,
      }
      $require = undef
    }

    if $services != undef {
      service { $services:
        ensure    => stopped,
        enable    => false,
        hasstatus => true,
        require   => $require,
      }
    }

  }
  else {
    notfiy { 'dchp::disable nothing to do need ipv4 or ipv6 parameter true': }
  }
}
