require 'spec_helper_acceptance'

describe 'Task foreman_hammer::get_host' do
  context 'with hostname=test01.mgmt.example.de' do
    describe 'get json info about the host' do
      params = {
        'name' => 'test01.mgmt.example.de',
        'hammer_cli_bin'   => '/usr/bin/hammer',
        'server_url'       => 'https://127.0.0.1',
        'username'         => 'admin',
        'password'         => 'secret',
        '_noop'            => true,
        'verbose'          => true,
      }

      it 'with the right hammer command' do
        result = run_bolt_task('foreman_hammer::get_host', params)
        expect(result['result']['result']).to eq("/usr/bin/hammer -s https://127.0.0.1 -u admin -p secret --output json host info --name 'test01.mgmt.example.de'")
      end
    end
  end
end
