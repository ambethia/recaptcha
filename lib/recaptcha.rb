require 'recaptcha/configuration'
require 'recaptcha/client_helper'
require 'recaptcha/verify'
require 'uri'
require 'net/http'

module Recaptcha
  CONFIG = {
    'server_url' => 'https://www.google.com/recaptcha/api.js',
    'verify_url' => 'https://www.google.com/recaptcha/api/siteverify'
  }.freeze

  USE_SSL_BY_DEFAULT              = false
  HANDLE_TIMEOUTS_GRACEFULLY      = true
  DEFAULT_TIMEOUT = 3

  # Gives access to the current Configuration.
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Allows easy setting of multiple configuration options. See Configuration
  # for all available options.
  #--
  # The temp assignment is only used to get a nicer rdoc. Feel free to remove
  # this hack.
  #++
  def self.configure
    config = configuration
    yield(config)
  end

  def self.with_configuration(config)
    original_config = {}

    config.each do |key, value|
      original_config[key] = configuration.send(key)
      configuration.send("#{key}=", value)
    end

    yield if block_given?
  ensure
    original_config.each { |key, value| configuration.send("#{key}=", value) }
  end

  def self.get(verify_hash, options)
    http = if Recaptcha.configuration.proxy
      proxy_server = URI.parse(Recaptcha.configuration.proxy)
      Net::HTTP::Proxy(proxy_server.host, proxy_server.port, proxy_server.user, proxy_server.password)
    else
      Net::HTTP
    end
    query = URI.encode_www_form(verify_hash)
    uri = URI.parse(Recaptcha.configuration.verify_url + '?' + query)
    http_instance = http.new(uri.host, uri.port)
    http_instance.read_timeout = http_instance.open_timeout = options[:timeout] || DEFAULT_TIMEOUT
    http_instance.use_ssl = true if uri.port == 443
    request = Net::HTTP::Get.new(uri.request_uri)
    http_instance.request(request).body
  end

  def self.i18n(key, default)
    if defined?(I18n)
      I18n.translate(key, default: default)
    else
      default
    end
  end

  class RecaptchaError < StandardError
  end

  class VerifyError < RecaptchaError
  end
end
