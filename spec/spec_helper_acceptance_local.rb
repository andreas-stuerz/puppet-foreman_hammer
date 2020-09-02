# frozen_string_literal: true

require 'singleton'

class LitmusHelper
  include Singleton
  include PuppetLitmus
end

# load hash from a yaml file under fixtures
def hash_from_fixture_yaml_file(fixture_path)
  fixture_yaml_path = File.join(File.dirname(__FILE__), 'fixtures', fixture_path)
  yaml_file = File.read(fixture_yaml_path)
  YAML.safe_load(yaml_file)
end

# create a file on the test machine
def create_remote_file(name, dest_filepath, file_content)
  Tempfile.open name do |tempfile|
    File.open(tempfile.path, 'w') { |file| file.puts file_content }
    LitmusHelper.instance.bolt_upload_file(tempfile.path, dest_filepath)
  end
end

def deploy_fixtures(target_dir = '/fixtures')
  local_fixtures_dir = File.join(File.dirname(__FILE__), '/fixtures/acceptance')
  LitmusHelper.instance.run_shell("rm -rf #{target_dir}")
  LitmusHelper.instance.bolt_upload_file(local_fixtures_dir, target_dir)
end

RSpec.configure do |c|
  c.before :suite do
    vmhostname = LitmusHelper.instance.run_shell('hostname').stdout.strip
    vmipaddr = LitmusHelper.instance.run_shell("ip route get 8.8.8.8 | awk '{print $NF; exit}'").stdout.strip
    if os[:family] == 'redhat'
      vmipaddr = LitmusHelper.instance.run_shell("ip route get 8.8.8.8 | awk '{print $7; exit}'").stdout.strip
    end
    vmos = os[:family]
    vmrelease = os[:release]
    puts "Running acceptance test on #{vmhostname} with address #{vmipaddr} and OS #{vmos} #{vmrelease}"

    # copy foreman_hammer templates fixtures to vm
    deploy_fixtures

    if os[:family] == 'redhat'
      base_url = "https://yum.theforeman.org/latest/el#{os[:release].to_i}/$basearch"
      plugin_base_url = "https://yum.theforeman.org/plugins/latest/el#{os[:release].to_i}/$basearch"
      gpg_key = 'http://yum.theforeman.org/latest/RPM-GPG-KEY-foreman'

      packages = <<-MANIFEST
          $packages = [
              'python3',
              'python3-pip',
              'foreman-release',
              'foreman-release-scl',
              'tfm-rubygem-hammer_cli',
              'tfm-rubygem-hammer_cli_foreman',
          ]
      MANIFEST

      if os[:release].to_i == 8
        packages = <<-MANIFEST
          $packages = [
              'python3',
              'python3-pip',
              'foreman-release',
              'rubygem-hammer_cli',
              'rubygem-hammer_cli_foreman',
          ]
        MANIFEST
      end

      # install dependencies on rhel based systems
      pp_setup = <<-MANIFEST
            #{packages}
            $pip_packges = [
              'ruamel.yaml',
              'Jinja2'
            ]
             yumrepo { 'foreman':
              descr    => 'Foreman #{os[:release].to_i} - $basearch',
              baseurl  => '#{base_url}',
              gpgkey   => '#{gpg_key}',
              enabled  => 1,
              gpgcheck => 1,
            }
            yumrepo { 'foreman-plugins':
              descr    => 'Foreman plugins #{os[:release].to_i} - $basearch',
              baseurl  => '#{plugin_base_url}',
              gpgkey   => '#{gpg_key}',
              enabled  => 1,
              gpgcheck => 1,
            }
            package { $packages:
              ensure => present,
            }
            -> package { $pip_packges:
              ensure   => latest,
              provider => 'pip3',
            }
      MANIFEST
    else
      # needed for the puppet fact
      LitmusHelper.instance.apply_manifest("package { ['lsb-release', 'gnupg']: ensure => installed, }", expect_failures: false)

      if os[:release] =~ %r{9|^16\.04}
        foreman_version = '1.24'
      elsif os[:release] =~ %r{10|^18\.04}
        foreman_version = '2.1'
      end

      LitmusHelper.instance.run_shell('puppet module install puppetlabs-apt')
      packages = <<-MANIFEST
          $packages = [
              'python3',
              'python3-pip',
              'ruby-hammer-cli',
              'ruby-hammer-cli-foreman',
          ]
      MANIFEST
      pp_setup = <<-MANIFEST
        Apt::Source <| |> -> Package <| |>
        #{packages}
        $pip_packges = [
          'ruamel.yaml',
          'Jinja2'
        ]
        apt::source { 'foreman':
          location => 'http://deb.theforeman.org',
          release  => "${::lsbdistcodename}",
          repos    => '#{foreman_version}',
          key      => {
            'id'     => 'AE0AF310E2EA96B6B6F4BD726F8600B9563278F6',
            'source' => 'http://deb.theforeman.org/pubkey.gpg',
          },
        }
        apt::source { 'foreman-plugins':
          location => 'http://deb.theforeman.org',
          release  => 'plugins',
          repos    => '#{foreman_version}',
          key      => {
            'id'     => 'AE0AF310E2EA96B6B6F4BD726F8600B9563278F6',
            'source' => 'http://deb.theforeman.org/pubkey.gpg',
          },
        }
        package { $packages:
          ensure => present,
        }
        -> package { $pip_packges:
          ensure   => latest,
          provider => 'pip3',
        }

      MANIFEST
    end

    LitmusHelper.instance.apply_manifest(pp_setup, expect_failures: false)
  end
end
