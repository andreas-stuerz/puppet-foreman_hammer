plan foreman::hosts (
  TargetSpec $targets,
  Hash $hosts,
  Boolean $noop,
  String $template_basedir = 'Boltdir/site-modules/foreman/templates',
) {
  # get group configuration variables
  if get_targets($targets).length > 0 {
    $config = get_targets($targets)[0].vars
  }

  $output = $hosts.map |$hostname, $host_config| {
    # check if host already exists
    $get_host_result = run_task(
      'foreman::get_host',
      $targets,
      name           => "${host_config['hostname']}${host_config['dns_suffix']}",
      server_url     => $config['foreman']['server_url'],
      username       => $config['foreman']['username'],
      password       => $config['foreman']['password'],
      hammer_cli_bin => $config['foreman']['hammer_cli_bin'],
      _noop          => $noop,
    )

    if (empty($get_host_result.first.value['result'])) {
      if $host_config['ip'] {
        $ip = $host_config['ip']
      } else {
        $ip = 'dhcp'
      }
      out::message(
        "Create server - HOSTNAME: ${hostname} IP: ${ip} TEMPLATE: ${host_config['template']} " +
        "CPU: ${host_config['cpus']} cores RAM: ${host_config['mem']} GB"
      )
      run_task(
        'foreman::create_host',
        $targets,
        hostname         => $host_config['hostname'],
        ip               => $host_config['ip'],
        template_basedir => $template_basedir,
        template         => $host_config['template'],
        cpus             => $host_config['cpus'],
        mem              => $host_config['mem'],
        server_url       => $config['foreman']['server_url'],
        username         => $config['foreman']['username'],
        password         => $config['foreman']['password'],
        hammer_cli_bin   => $config['foreman']['hammer_cli_bin'],
        _noop            => $noop,
      )
    } else {
      $id = $get_host_result.first.value['result']['Id']
      $name = $get_host_result.first.value['result']['Name']
      $ip = $get_host_result.first.value['result']['Network']['IPv4 address']

      out::message(
        "Update server - ID: ${id} NAME: ${name} IP: ${ip} TEMPLATE: ${host_config['template']} " +
        "CPU: ${host_config['cpus']} cores RAM: ${host_config['mem']} GB"
      )
      run_task(
      'foreman::update_host',
        $targets,
        id               => $id,
        template         => $host_config['template'],
        template_basedir => $template_basedir,
        cpus             => $host_config['cpus'],
        mem              => $host_config['mem'],
        build            => $host_config['rebuild'],
        server_url       => $config['foreman']['server_url'],
        username         => $config['foreman']['username'],
        password         => $config['foreman']['password'],
        hammer_cli_bin   => $config['foreman']['hammer_cli_bin'],
        _noop            => $noop,
      )
    }
  }
  return $output
}