#!/bin/sh
pdk bundle install
pdk bundle exec rake 'litmus:provision_list[default]'
pdk bundle exec rake 'litmus:install_agent[puppet6]'
pdk bundle exec rake litmus:install_module
