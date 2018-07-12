#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require

require './cleanup.rb'

registry_url = ENV['REGISTRY_URL'] || 'http://localhost:5000'
keep_tags = ENV['KEEP_TAGS'] || 3
cleanup_cron = ENV['CLEANUP_CRON'] || '5 0 * * *'

def safe_system(*args)
  system(*args)
  raise "Command failed #{args}" if $? != 0
end

def run_cleanup(registry_url, keep_tags)
  clean_registry(registry_url, keep_tags)
  safe_system "supervisorctl -c /etc/supervisord.conf stop docker-registry"
  safe_system "/bin/registry garbage-collect /etc/docker/registry/config.yml"
  safe_system "supervisorctl -c /etc/supervisord.conf start docker-registry"
end

scheduler = Rufus::Scheduler.new

scheduler.cron cleanup_cron do
  run_cleanup(registry_url, keep_tags)
end

print "Starting docker registry cleaner, schedule: #{cleanup_cron} ...\n"
STDOUT.flush

scheduler.join
