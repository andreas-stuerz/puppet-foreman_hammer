#!/usr/bin/env python3

"""
Update a host in foreman via yaml template
"""
import os
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'python_task_helper', 'files'))
from task_helper import TaskHelper

sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'foreman_hammer', 'lib'))
from hammer_cli_helper import HammerCliHelper

class MyTask(TaskHelper):
    def task(self, args):
        id = args['id']
        ip = args.get('ip', '')
        build = args['build']
        cpus = args.get('cpus', '')
        mem = args.get('mem', '')
        template = args['template']
        server_url = args.get('server_url', '')
        username = args.get('username', '')
        password = args.get('password', '')
        hammer_cli_bin = os.path.expanduser(args['hammer_cli_bin'])
        template_basedir = args['template_basedir']
        template_path = os.path.abspath(os.path.join(template_basedir, template))
        noop = args.get('_noop', False)

        hammer_helper = HammerCliHelper()

        host_template_data = hammer_helper.dict_from_yaml(template_path)
        host_input_data = {
            "root": {
                "id": id,
                "build": build,
            }
        }

        if cpus or mem:
            host_input_data['compute-attributes'] = {
                'cores': cpus,
                'memory': mem * hammer_helper.GB_IN_BYTES
            }

        if ip:
            host_input_data['root']['ip'] = ip

        host_data = hammer_helper.merge_templates(host_template_data, host_input_data)

        # search in host_data for key and delete the item if a match is found
        ignore_keys = {
            "volume": {
                "bootable": True,
            },
            "interface": {
                "primary": True
            },
        }
        # remove ignored keys matching values
        for key in ignore_keys.keys():
            if host_data.get(key):
                if type(host_data[key]) is list:
                    for index, item in enumerate(host_data[key]):
                        for search_key, search_val in ignore_keys[key].items():
                            if item.get(search_key) == search_val:
                                host_data[key].pop(index)
                                break

        # build command string
        base_command = "%s %s %s %s" \
                       % (hammer_cli_bin,
                           "-s %s" % server_url if server_url else '',
                           "-u %s" % username if username else '',
                           "-p %s" % password if password else '',
                        )

        # execute command
        command = "%s host update %s" % (base_command, hammer_helper.dict_to_hammer_cli_options(host_data))
        output = command if noop else hammer_helper.hammer_fall(command)
        return {
            'result': output
        }

if __name__ == '__main__':
    MyTask().run()
