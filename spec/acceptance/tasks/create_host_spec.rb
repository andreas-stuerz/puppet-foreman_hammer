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
          '_noop'            => true
      }

      it 'with the right hammer command' do
        result = run_bolt_task('foreman_hammer::create_host', params)
        expect(result['result']['result']).to eq("/usr/bin/hammer -s https://127.0.0.1 -u admin -p secret host create --organization 'example.de' --location 'DC1' --hostgroup 'linux-servers-dc1' --puppet-environment 'development' --puppet-proxy 'foreman.example.com' --puppet-ca-proxy 'foreman.example.com' --architecture 'x86_64' --operatingsystem 'CentOS Linux' --medium 'CentOS mirror' --provision-method 'build' --build true --partition-table 'Linux' --pxe-loader 'PXELinux BIOS' --compute-resource 'oVirt' --compute-attributes 'cluster=65c8d284-8f8f-11e9-833f-00163e6c9c8e,template=94c889e6-03cc-4ce8-bdd8-af994756751f,cores=2,sockets=1,memory=4294967296,start=1' --volume 'size_gb=40,storage_domain=9b5fa395-18bb-47a1-a499-92121534ff6c,preallocate=false,interface=virtio,bootable=true' --interface 'identifier=ens3,domain_id=1,subnet_id=5,primary=true,managed=true,provision=true,compute_name=nic0,compute_network=00000000-0000-0000-0000-000000000005,compute_interface=virtio' --name 'test01' --ip '10.0.0.1'")
      end
    end
  end
end