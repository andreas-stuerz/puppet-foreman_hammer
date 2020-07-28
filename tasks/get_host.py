#!/usr/bin/env python3

"""
This script get information for a host from foreman
Requires:
- hammer-cli-foreman -See: https://github.com/theforeman/hammer-cli-foreman
"""
import os
import sys
import json
import subprocess
import shlex

sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'python_task_helper', 'files'))
from task_helper import TaskHelper

class HammerCliError(Exception):
    def __init__(self, code, msg):
        message = "Exit code: {} - Error: {}".format(code, msg)
        super().__init__(message)

class MyTask(TaskHelper):
    def hammer_fall(self, command, encoding = 'UTF-8'):
        args = shlex.split(command)
        p = subprocess.Popen(args, shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output,error = p.communicate()
        if error and p.returncode != 70:
            raise HammerCliError(p.returncode, error.decode(encoding))
        if p.returncode == 70:
            return '{}'
        return output.decode(encoding)

    def task(self, args):
        name = args['name']
        server_url = args.get('server_url', '')
        username = args.get('username', '')
        password = args.get('password', '')
        hammer_cli_bin = os.path.expanduser(args['hammer_cli_bin'])
        noop = args.get('_noop', False)

        # build command string
        base_command = "%s %s %s %s" \
                       % (hammer_cli_bin,
                           "-s %s" % server_url if server_url else '',
                           "-u %s" % username if username else '',
                           "-p %s" % password if password else '',
                        )
        # execute command
        command = "%s --output json host info --name '%s'" % (base_command, name)
        output = command if noop else json.loads(self.hammer_fall(command))
        if noop:
            print(command)
        return {
            'result': output
        }

if __name__ == '__main__':
    MyTask().run()
