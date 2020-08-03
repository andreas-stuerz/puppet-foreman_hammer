#!/usr/bin/env python3

"""
This script update a host in foreman via template
Requires:
- hammer-cli-foreman -See: https://github.com/theforeman/hammer-cli-foreman
- pip install pyyaml
"""
import os
import sys
import yaml
import subprocess
import shlex

sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'python_task_helper', 'files'))
from task_helper import TaskHelper

class HammerCliError(Exception):
    def __init__(self, code, msg):
        message = "Exit code: {} - Error: {}".format(code, msg)
        super().__init__(message)

class MyTask(TaskHelper):
    GB_IN_BYTES = 1073741824
    def hammer_fall(self, command, encoding = 'UTF-8'):
        args = shlex.split(command)
        p = subprocess.Popen(args, shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output,error = p.communicate()
        if error:
            raise HammerCliError(p.returncode, error.decode(encoding))
        return output.decode(encoding)

    def dict_from_yaml(self, path):
        with open(path) as yaml_file:
            data = yaml.load(yaml_file, Loader=yaml.FullLoader)
        return data

    def get_safe_option_value(self, value, string_template = "'{}'"):
        if isinstance(value, str):
            result = string_template.format(value.replace(',', '\,'))
        elif isinstance(value, bool):
            result = str(value).lower()
        else:
            result = value
        return result

    def get_comma_seperated(self, dict):
        list = []
        for key, value in dict.items():
            list.append("{}={}".format(key, self.get_safe_option_value(value, "{}")))
        return ",".join(list)

    def dict_to_hammer_cli_options(self, dict):
        option_lines = []
        for key, value in dict.items():
            if type(value) is type(dict):
                option_lines.append("--{} '{}'".format(key, self.get_comma_seperated(value)))
            elif type(value) is list:
                for option_detail in value:
                    option_lines.append("--{} '{}'".format(key, self.get_comma_seperated(option_detail)))
            else:
                option_lines.append("--{} {}".format(key, self.get_safe_option_value(value)))
        return " ".join(option_lines)

    def merge_templates(self, template, override_template):
        for key in override_template.keys():
            if key == 'root':
                template.update(override_template[key])
            else:
                template[key].update(override_template[key])
        return template

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

        host_template_data = self.dict_from_yaml(template_path)
        host_input_data = {
            "root": {
                "id": id,
                "build": build,
            }
        }

        if cpus or mem:
            host_input_data['compute-attributes'] = {
                'cores': cpus,
                'memory': mem * self.GB_IN_BYTES
            }

        if ip:
            host_input_data['root']['ip'] = ip

        host_data = self.merge_templates(host_template_data, host_input_data)

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
        command = "%s host update %s" % (base_command, self.dict_to_hammer_cli_options(host_data))
        output = command if noop else self.hammer_fall(command)
        return {
            'result': output
        }

if __name__ == '__main__':
    MyTask().run()
