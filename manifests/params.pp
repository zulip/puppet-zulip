class puppet_zulip::params {

  if $::is_pe == 'true' {
    $puppetconf_path = '/etc/puppetlabs/puppet'
  } else {
    $puppetconf_path = '/etc/puppet'
  }
}