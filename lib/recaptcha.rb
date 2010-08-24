require 'recaptcha/configuration'
require 'recaptcha/client_helper'
require 'recaptcha/verify'

module Recaptcha
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 2
    TINY  = 2
    PATCH = 1

    STRING = [MAJOR, MINOR, TINY, PATCH].join('.')
  end

  
  RECAPTCHA_API_SERVER_URL        = 'http://api.recaptcha.net';
  RECAPTCHA_API_SECURE_SERVER_URL = 'https://api-secure.recaptcha.net';
  RECAPTCHA_VERIFY_URL            = 'http://api-verify.recaptcha.net/verify';

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

  class RecaptchaError < StandardError
  end
end
