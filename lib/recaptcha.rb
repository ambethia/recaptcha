# frozen_string_literal: true

require 'recaptcha/configuration'
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

  def self.i18n(key, default)
    if defined?(I18n)
      I18n.translate(key, default: default)
    else
      default
    end
  end

  class RecaptchaError < StandardError
  end
end

if defined?(Rails)
  require 'recaptcha/railtie'
else
  require 'recaptcha/client_helper'
  require 'recaptcha/verify'
end
