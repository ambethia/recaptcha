require 'recaptcha/configuration'
require 'recaptcha/client_helper'
require 'recaptcha/verify'

module Recaptcha
  CONFIG =
    {
      'v1' => {
        'server_url' => '//www.google.com/recaptcha/api',
        'secure_server_url' => 'https://www.google.com/recaptcha/api',
        'verify_url' => 'http://www.google.com/recaptcha/api/verify'
      },

      'v2' => {
        'server_url' => '//www.google.com/recaptcha/api.js',
        'secure_server_url' => 'https://www.google.com/recaptcha/api.js',
        'verify_url' => 'https://www.google.com/recaptcha/api/siteverify'
      }
    }

  RECAPTCHA_API_VERSION           = 'v2' 
  USE_SSL_BY_DEFAULT              = false
  HANDLE_TIMEOUTS_GRACEFULLY      = true
  SKIP_VERIFY_ENV = ['test', 'cucumber']

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

    result = yield if block_given?

    original_config.each { |key, value| configuration.send("#{key}=", value) }
    result
  end

  class RecaptchaError < StandardError
  end

  class VerifyError < RecaptchaError
  end

end

if defined?(Rails)
  require 'recaptcha/rails'
end
