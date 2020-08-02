require 'spec_helper_acceptance'

# fixture yaml template dir
template_dir = File.join(File.dirname(__FILE__), '/../../fixtures/acceptance/host_templates')

describe 'Task: foreman_hammer::create_host' do
  context 'with host=test01 from template=centos7.yaml' do
    describe 'creates the host test01.example.com' do
      params = {
          'hostname'         => 'test01',
          'template'         => 'centos7.yaml',
          'template_basedir' =>  template_dir
      }

      it 'works without errors' do
        run_bolt_task('foreman_hammer::create_host', params)
      end
    end
  end
end