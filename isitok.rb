#!/usr/bin/env ruby

require 'yaml'
require 'bundler'
Bundler.require(:default)

String.disable_colorization(true) unless STDOUT.isatty
LOGGER = Logger.new(STDOUT, level: ENV['DEBUG'] ? :debug : :info)

def reload_config
  config = YAML.load_file('isitok.yaml')
  $delay = config['notifications']['delay'] || 150
  $tlgr  = config['telegram'] || {}
  $sites = config['sites'] || {}
end
reload_config

def send_notification(msg)
  LOGGER.debug "Attempting to send message via telegram: #{msg.bold}"
  return unless $tlgr['chat_id']

  LOGGER.debug "Sending message via telegram, chat id: #{$tlgr['chat_id']}"
  Typhoeus.post("https://api.telegram.org/bot#{$tlgr['api_id']}/sendMessage", body: {
    chat_id: $tlgr['chat_id'],
    parse_mode: 'markdown',
    text: msg
  })
end

def shut_down
  Thread.new {
    send_notification("*Availability notification is OFF*")
    exit
  }
end
Signal.trap("INT")  { shut_down }
Signal.trap("TERM") { shut_down }

send_notification("*Availability notification is ON*\nActive checks: #{$sites.keys.to_sentence}")

prev_problems = {}
while true
  current_problems = {}
  $sites.each do |site, paths|
    paths.each do |path, check|
      if check == 'GET'
        url = 'https://' + site + path
        resp = Typhoeus.get(url)
        LOGGER.info "GET #{url} " + (resp.success? ? 'OK'.green : 'FAILED'.red)
        if ! resp.success?
          send_notification("Failed GET #{url}") unless prev_problems[site + path]
          current_problems[site + path] = true
        end
      else
        fail
      end
    end

    if prev_problems.values.any? && ! current_problems.values.any?
      send_notification("*All availability checks pass*\nActive checks: #{$sites.keys.to_sentence}")
    end
    prev_problems = current_problems
  end

  sleep $delay
  reload_config
end
