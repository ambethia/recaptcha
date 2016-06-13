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
  # Please note that the public and private key for the reCAPTCHA API Access
  # have no useful default value. The keys may be set via the Shell enviroment
  # or using this configuration. Settings within this configuration always take
  # precedence.
  #
  # Setting the keys with this Configuration
  #
  #   Recaptcha.configure do |config|
  #     config.public_key  = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'
  #     config.private_key = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
  #   end
  #
  class Configuration
    attr_accessor :skip_verify_env, :private_key, :public_key, :proxy, :handle_timeouts_gracefully, :hostname

    def initialize #:nodoc:
      @skip_verify_env            = %w[test cucumber]
      @handle_timeouts_gracefully = HANDLE_TIMEOUTS_GRACEFULLY

      @private_key           = ENV['RECAPTCHA_PRIVATE_KEY']
      @public_key            = ENV['RECAPTCHA_PUBLIC_KEY']
    end

    def private_key!
      private_key || raise(RecaptchaError, "No private key specified.")
    end

    def public_key!
      public_key || raise(RecaptchaError, "No public key specified.")
    end

    def api_server_url
      CONFIG.fetch('server_url')
    end

    def verify_url
      CONFIG.fetch('verify_url')
    end
  end
end
