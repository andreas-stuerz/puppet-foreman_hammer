# Create or update an existing host from a list of hosts with hammer_cli in foreman
# @param targets The list of targets to run the plan
# @param lookup_key The hiera base lookup key.
# @param hosts A list of hosts to create or update.
# @param template_basedir The base directory for the foreman yaml templates
# @param noop Turn on noop mode.
plan foreman_hammer::hosts (
  TargetSpec $targets,
  String     $lookup_key = 'foreman_hammer',
  Hash       $hosts = lookup("${lookup_key}::hosts", Hash, 'deep', {}),
  String     $template_basedir = lookup("${lookup_key}::template_basedir", String, 'deep', 'data/host_templates'),
  Boolean    $noop = false,
) {
  # get group configuration variables
  if get_targets($targets).length > 0 {
    $config = get_targets($targets)[0].vars
  }

  $output = $hosts.map |$hostname, $host_config| {
    # check if host already exists
    $get_host_result = run_task(
      'foreman_hammer::get_host',
      $targets,
      name           => "${host_config['hostname']}${host_config['dns_suffix']}",
      server_url     => $config['foreman']['server_url'],
      username       => $config['foreman']['username'],
      password       => $config['foreman']['password'],
      hammer_cli_bin => $config['foreman']['hammer_cli_bin'],
    )

    if (empty($get_host_result.first.value['result'])) {
      if $host_config['ip'] {
        $ip = $host_config['ip']
      } else {
        $ip = 'dhcp'
      }
      out::message(sprintf('Create server - HOSTNAME: %s IP: %s TEMPLATE: %s CPU: %s cores RAM: %s GB ',
          $hostname, $ip, $host_config['template'], $host_config['cpus'], $host_config['mem']
        )
      )
      run_task(
        'foreman_hammer::create_host',
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

      out::message(sprintf('Update server - ID: %s NAME: %s IP: %s TEMPLATE: %s CPU: %s cores RAM: %s GB ',
          $id, $name, $ip, $host_config['template'], $host_config['cpus'], $host_config['mem']
        )
      )
      run_task(
      'foreman_hammer::update_host',
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