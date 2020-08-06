require 'spec_helper_acceptance'

describe 'Task foreman_hammer::update_host' do
  context 'with id=1 from template=centos7.yaml' do
    describe 'updates the host test01.example.com' do
      params = {
        'template_basedir' => '/fixtures/host_templates',
        'id'               => 1,
        'template'         => 'centos7.yaml',
        'build'            => true,
        'ip'               => '10.0.0.1',
        'cpus'             => 4,
        'mem'              => 8,
        'hammer_cli_bin'   => '/usr/bin/hammer',
        'server_url'       => 'https://127.0.0.1',
        'username'         => 'admin',
        'password'         => 'secret',
        '_noop'            => true,
      }

      it 'with the right hammer command' do
        result = run_bolt_task('foreman_hammer::update_host', params)
        # rubocop:disable LineLength
        expect(result['result']['result']).to eq("/usr/bin/hammer -s https://127.0.0.1 -u admin -p secret host update --architecture 'x86_64' --build true --compute-attributes 'cluster=65c8d284-8f8f-11e9-833f-00163e6c9c8e,cores=4,memory=8589934592,sockets=1,start=1,template=94c889e6-03cc-4ce8-bdd8-af994756751f' --compute-resource 'oVirt' --hostgroup 'linux-servers-dc1' --id 1 --ip '10.0.0.1' --location 'DC1' --medium 'CentOS mirror' --operatingsystem 'CentOS Linux' --organization 'example.de' --partition-table 'Linux' --provision-method 'build' --puppet-ca-proxy 'foreman.example.com' --puppet-environment 'development' --puppet-proxy 'foreman.example.com' --pxe-loader 'PXELinux BIOS'")
        # rubocop:enable LineLength
      end
    end
  end
end
