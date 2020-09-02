#!/usr/bin/env python3
# coding: utf8
"""
Python helper class for hammer cli

Requires:
    - hammer-cli-foreman -See: https://github.com/theforeman/hammer-cli-foreman
    - pip install pyyaml
"""
from ruamel import yaml
import subprocess
import shlex
import os
from jinja2 import Environment, FileSystemLoader

class HammerCliError(Exception):
    def __init__(self, code, msg):
        message = "Exit code: {} - Error: {}".format(code, msg)
        super().__init__(message)

class HammerCliHelper():
    GB_IN_BYTES = 1073741824
    def hammer_fall(self, command, valid_returncodes = [], encoding = 'UTF-8'):
        args = shlex.split(command)
        p = subprocess.Popen(args, shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output,error = p.communicate()
        if error and p.returncode not in valid_returncodes:
            raise HammerCliError(p.returncode, error.decode(encoding))
        if p.returncode in valid_returncodes:
            return '{}'
        return output.decode(encoding)

    def render_jinja2_template(self, path, vars):
        template_dir = os.path.dirname(path)
        template = os.path.basename(path)
        env = Environment(loader = FileSystemLoader(template_dir), trim_blocks=True, lstrip_blocks=True)
        template = env.get_template(template)
        return template.render(vars)

    def dict_from_yaml_string(self, yaml_str):
        data = yaml.safe_load(yaml_str)
        return data

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
        for key in sorted(dict.keys()):
            list.append("{}={}".format(key, self.get_safe_option_value(dict[key], "{}")))
        return ",".join(list)

    def dict_to_hammer_cli_options(self, dict):
        option_lines = []
        for key in sorted(dict.keys()):
            if type(dict[key]) is type(dict):
                option_lines.append("--{} '{}'".format(key, self.get_comma_seperated(dict[key])))
            elif type(dict[key]) is list:
                for option_detail in dict[key]:
                    option_lines.append("--{} '{}'".format(key, self.get_comma_seperated(option_detail)))
            else:
                option_lines.append("--{} {}".format(key, self.get_safe_option_value(dict[key])))
        return " ".join(option_lines)

    def merge_templates(self, template, override_template):
        for key in override_template.keys():
            if key == 'root':
                template.update(override_template[key])
            else:
                template[key].update(override_template[key])
        return template


