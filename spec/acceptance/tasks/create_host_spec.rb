require 'spec_helper_acceptance'

describe 'Task: foreman_hammer::create_host' do
  context 'with host=test01 from template=centos7.yaml' do
    describe 'creates the host test01.example.com' do
      params = {
        'template_basedir' => '/fixtures/host_templates',
        'hostname'         => 'test01',
        'template'         => 'centos7.yaml',
        'ip'               => '10.0.0.1',
        'cpus'             => 2,
        'mem'              => 4,
        'hammer_cli_bin'   => '/usr/bin/hammer',
        'server_url'       => 'https://127.0.0.1',
        'username'         => 'admin',
        'password'         => 'secret',
        '_noop'            => true,
      }

      it 'with the right hammer command' do
        result = run_bolt_task('foreman_hammer::create_host', params)
        # rubocop:disable LineLength
        expect(result['result']['result']).to eq("/usr/bin/hammer -s https://127.0.0.1 -u admin -p secret host create --architecture 'x86_64' --build true --compute-attributes 'cluster=65c8d284-8f8f-11e9-833f-00163e6c9c8e,cores=2,memory=4294967296,sockets=1,start=1,template=94c889e6-03cc-4ce8-bdd8-af994756751f' --compute-resource 'oVirt' --hostgroup 'linux-servers-dc1' --interface 'compute_interface=virtio,compute_name=nic0,compute_network=00000000-0000-0000-0000-000000000005,domain_id=1,identifier=ens3,managed=true,primary=true,provision=true,subnet_id=5' --ip '10.0.0.1' --location 'DC1' --medium 'CentOS mirror' --name 'test01' --operatingsystem 'CentOS Linux' --organization 'example.de' --partition-table 'Linux' --provision-method 'build' --puppet-ca-proxy 'foreman.example.com' --puppet-environment 'development' --puppet-proxy 'foreman.example.com' --pxe-loader 'PXELinux BIOS' --volume 'bootable=true,interface=virtio,preallocate=false,size_gb=40,storage_domain=9b5fa395-18bb-47a1-a499-92121534ff6c'")
        # rubocop:enable LineLength
      end
    end
  end
end
