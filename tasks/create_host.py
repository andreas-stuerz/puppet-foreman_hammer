#!/usr/bin/env python3

"""
Create a host in foreman via yaml template
"""
import os
import sys


sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'python_task_helper', 'files'))
from task_helper import TaskHelper

sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'foreman_hammer', 'lib'))
from hammer_cli_helper import HammerCliHelper

class MyTask(TaskHelper):
    def task(self, args):
        hostname = args['hostname']
        cpus = args.get('cpus', '')
        mem = args.get('mem', '')
        template_file = args['template']
        ip = args.get('ip', '')
        server_url = args.get('server_url', '')
        username = args.get('username', '')
        password = args.get('password', '')
        hammer_cli_bin = os.path.expanduser(args['hammer_cli_bin'])
        template_basedir = args['template_basedir']
        template_path = os.path.abspath(os.path.join(template_basedir, template_file))
        template_vars = args['template_vars']
        noop = args.get('_noop', False)
        verbose = args['verbose']

        hammer_helper = HammerCliHelper()
        foreman_yaml = hammer_helper.render_jinja2_template(template_path, template_vars)
        host_template_data = hammer_helper.dict_from_yaml_string(foreman_yaml)

        host_input_data = {
            "root": {
                "name": hostname,
            }
        }

        if ip:
            host_input_data['root']['ip'] = ip

        if cpus or mem:
            host_input_data['compute-attributes'] = {
                'cores': cpus,
                'memory': mem * hammer_helper.GB_IN_BYTES
            }

        host_data = hammer_helper.merge_templates(host_template_data, host_input_data)

        # hide pw in noop mode
        if password and noop and not verbose:
            password = "XXXXXXXXXXXXX"

        # build command string
        base_command = "%s %s %s %s" \
                       % (hammer_cli_bin,
                           "-s %s" % server_url if server_url else '',
                           "-u %s" % username if username else '',
                           "-p %s" % password if password else '',
                        )

        # execute command
        command = "%s host create %s" % (base_command, hammer_helper.dict_to_hammer_cli_options(host_data))
        output = command if noop else hammer_helper.hammer_fall(command)
        return {
            'result': output
        }

if __name__ == '__main__':
    MyTask().run()
