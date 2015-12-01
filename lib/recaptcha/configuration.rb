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
    attr_accessor :skip_verify_env, :private_key, :public_key, :proxy, :handle_timeouts_gracefully, :use_ssl_by_default

    def initialize #:nodoc:
      @skip_verify_env            = SKIP_VERIFY_ENV
      @handle_timeouts_gracefully = HANDLE_TIMEOUTS_GRACEFULLY
      @use_ssl_by_default         = USE_SSL_BY_DEFAULT

      @private_key           = ENV['RECAPTCHA_PRIVATE_KEY']
      @public_key            = ENV['RECAPTCHA_PUBLIC_KEY']
    end

    def private_key!
      private_key || raise(RecaptchaError, "No private key specified.")
    end

    def public_key!
      public_key || raise(RecaptchaError, "No public key specified.")
    end

    def api_server_url(ssl: nil)
      ssl = use_ssl_by_default if ssl.nil?
      key = (ssl ? 'secure_server_url' : 'server_url')
      CONFIG.fetch(key)
    end

    def verify_url
      CONFIG.fetch('verify_url')
    end

    def api_version=(v)
      if v == 'v2'
        warn 'setting api_version is deprecated and will be removed shortly, only v2 is supported'
      else
        raise ArgumentError, "only v2 is supported, not #{v.inspect}"
      end
    end

    def api_version
      warn 'getting api_version is deprecated and will be removed shortly, only v2 is supported'
      'v2'
    end
  end
end
