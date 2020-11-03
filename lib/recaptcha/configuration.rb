# frozen_string_literal: true

module Recaptcha
  # This class enables detailed configuration of the recaptcha services.
  #
  # By calling
  #
  #   Recaptcha.configuration # => instance of Recaptcha::Configuration
  #
  # or
  #   Recaptcha.configure do |config|
  #     config # => instance of Recaptcha::Configuration
  #   end
  #
  # you are able to perform configuration updates.
  #
  # Your are able to customize all attributes listed below. All values have
  # sensitive default and will very likely not need to be changed.
  #
  # Please note that the site and secret key for the reCAPTCHA API Access
  # have no useful default value. The keys may be set via the Shell enviroment
  # or using this configuration. Settings within this configuration always take
  # precedence.
  #
  # Setting the keys with this Configuration
  #
  #   Recaptcha.configure do |config|
  #     config.site_key  = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'
  #     config.secret_key = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
  #   end
  #
  class Configuration
    DEFAULTS = {
      'server_url' => 'https://www.google.com/recaptcha/api.js',
      'verify_url' => 'https://www.google.com/recaptcha/api/siteverify'
    }.freeze

    attr_accessor :default_env, :skip_verify_env, :api_server_url, :verify_url, :secret_key, :site_key,
                  :proxy, :handle_timeouts_gracefully, :hostname

    def initialize #:nodoc:
      @default_env = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || (Rails.env if defined? Rails.env)
      @skip_verify_env = %w[test cucumber]
      @handle_timeouts_gracefully = true

      @api_server_url = ENV['RECAPTCHA_SERVER_URL'] || DEFAULTS.fetch('server_url')
      @verify_url = ENV['RECAPTCHA_VERIFY_URL'] || DEFAULTS.fetch('verify_url')
      @secret_key = ENV['RECAPTCHA_SECRET_KEY']
      @site_key = ENV['RECAPTCHA_SITE_KEY']
    end

    def secret_key!
      secret_key || raise(RecaptchaError, "No secret key specified.")
    end

    def site_key!
      site_key || raise(RecaptchaError, "No site key specified.")
    end
  end
end
