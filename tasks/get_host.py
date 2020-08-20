#!/usr/bin/env python3

"""
This script get information for a host from foreman
"""
import os
import sys
import json

sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'python_task_helper', 'files'))
from task_helper import TaskHelper

sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'foreman_hammer', 'lib'))
from hammer_cli_helper import HammerCliHelper

class MyTask(TaskHelper):
    def task(self, args):
        name = args['name']
        server_url = args.get('server_url', '')
        username = args.get('username', '')
        password = args.get('password', '')
        hammer_cli_bin = os.path.expanduser(args['hammer_cli_bin'])
        noop = args.get('_noop', False)
        verbose = args['verbose']

        hammer_helper = HammerCliHelper()

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
        command = "%s --output json host info --name '%s'" % (base_command, name)
        output = command if noop else json.loads(hammer_helper.hammer_fall(command, [70]))
        return {
            'result': output
        }

if __name__ == '__main__':
    MyTask().run()
