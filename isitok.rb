#!/usr/bin/env ruby

require 'yaml'
require 'bundler'
Bundler.require(:default)

String.disable_colorization(true) unless STDOUT.isatty
LOGGER = Logger.new(STDOUT, level: ENV['DEBUG'] ? :debug : :info)

def send_notification(msg)
  LOGGER.debug "Attempting to send message via telegram: #{msg.bold}"
  return unless $tlgr['chat_id']
  return if ENV['DRYRUN']

  LOGGER.debug "Sending message via telegram, chat id: #{$tlgr['chat_id']}"
  Typhoeus.post("https://api.telegram.org/bot#{$tlgr['api_id']}/sendMessage", body: {
    chat_id: $tlgr['chat_id'],
    parse_mode: 'markdown',
    text: msg
  })
end

def reload_config
  old_config, $config = $config, YAML.load_file('isitok.yaml')
  $delay = $config['notifications']['delay'] || 150
  $tlgr  = $config['telegram'] || {}
  $sites = ($config['sites'] || {}).transform_values { |val| {val => nil} }
  $sites.deep_merge!($config['custom_checks'] || {})

  if old_config.blank?
    send_notification("*Availability notification is ON*\nActive checks: #{$sites.keys.to_sentence}")
  elsif old_config != $config
    send_notification("*Configuration changed*\nActive checks: #{$sites.keys.to_sentence}")
  end
end

def ok?(url, check)
  check ||= {'http_code' => '2\d\d'}
  http_code_re = /\A(#{check['http_code']})\z/

  resp = Typhoeus.get(url)
  result = resp.code.to_s.match?(http_code_re)

  LOGGER.info "GET #{url} => #{resp.code}: " + (result ? 'OK'.green : 'FAILED'.red)
  result
end

def shut_down
  Thread.new {
    send_notification("*Availability notification is OFF*")
    exit
  }
end
Signal.trap("INT")  { shut_down }
Signal.trap("TERM") { shut_down }

reload_config

prev_problems = {}
while true
  current_problems = {}
  $sites.each do |site, paths|
    paths ||= ['/']
    paths.each do |path, check|
      url = Addressable::URI.heuristic_parse(site + path, scheme: 'https')

      unless ok?(url, check)
        send_notification("Failed GET #{url}") unless prev_problems[url.to_s]
        current_problems[url.to_s] = true
      end
    end
  end

  if prev_problems.values.any? && ! current_problems.values.any?
    binding.pry
    send_notification("*All availability checks pass*\nActive checks: #{$sites.keys.to_sentence}")
  end
  prev_problems = current_problems

  sleep $delay
  reload_config
end
