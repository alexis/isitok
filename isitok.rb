#!/usr/bin/env ruby

require 'yaml'
require 'bundler'
Bundler.require(:default)

String.disable_colorization(true) unless STDOUT.isatty
LOGGER = Logger.new(STDOUT, level: ENV['DEBUG'] ? :debug : :info)

def send_notification(msg)
  LOGGER.debug "Preparing to send message via telegram: #{msg.bold}"
  return unless $chat_id
  return if ENV['DRYRUN']

  LOGGER.debug "Sending message via telegram, chat id: #{$chat_id}"
  Typhoeus.post("https://api.telegram.org/bot#{$api_token}/sendMessage", body: {
    chat_id: $chat_id,
    parse_mode: 'markdown',
    text: msg
  })
end

def notify_on_config_change(old_config)
  if old_config.blank?
    return if ENV['SKIP_GREETING']
    send_notification("*Availability notification is ON*\nActive checks: #{$sites.keys.to_sentence}")
  elsif old_config != $config
    send_notification("*Configuration changed*\nActive checks: #{$sites.keys.to_sentence}")
  end
end

def reload_config
  old_config, $config = $config, YAML.load_file('isitok.yaml')
  $delay = $config.dig('notifications', 'delay') || 150
  $retries = $config.dig('notifications', 'retries') || 0
  $api_token  = $config.dig('telegram', 'api_token')
  $chat_id  = $config.dig('telegram', 'chat_id')
  $sites = ($config['sites'] || {}).transform_values { |val| {val => nil} }
  $sites.deep_merge!($config['custom_checks'] || {})

  notify_on_config_change(old_config)
end

def ok?(url, check)
  check ||= {'http_code' => '2\d\d'}
  http_code_re = /\A(#{check['http_code']})\z/

  good = false
  tries_left = 1 + $retries

  until good || (tries_left -= 1) < 0
    resp = Typhoeus.get(url)
    good = resp.code.to_s.match?(http_code_re)

    LOGGER.debug "GET #{url} => #{resp.code}, #{resp.time}s"
  end

  LOGGER.info "GET #{url} => #{resp.code}: " + (good ? 'OK'.green : 'FAILED'.red)
  return good
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
    send_notification("*All availability checks pass*")
  end
  prev_problems = current_problems

  sleep $delay
  reload_config
end
