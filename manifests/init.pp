class puppet_zulip (
  $botemail,
  $key,
  $type,
  $to,
  $subject     = undef,
  $statuses    = [ 'failed' ],
  $config_file = "${puppet_zulip::params::puppetconf_path}/zulip.yaml",
) inherits puppet_zulip::params {

  file { $config_file:
    ensure  => file,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0440',
    content => template('puppet_zulip/zulip.yaml.erb'),
  }

}
