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
    attr_accessor :api_version,
                  :skip_verify_env,
                  :private_key,
                  :public_key,
                  :proxy,
                  :handle_timeouts_gracefully,
                  :use_ssl_by_default,
                  :v1_server_url,
                  :v1_secure_server_url,
                  :v1_verify_url,
                  :v2_server_url,
                  :v2_secure_server_url,
                  :v2_verify_url

    def initialize #:nodoc:
      @api_version                = RECAPTCHA_API_VERSION
      @skip_verify_env            = SKIP_VERIFY_ENV
      @handle_timeouts_gracefully = HANDLE_TIMEOUTS_GRACEFULLY
      @use_ssl_by_default         = USE_SSL_BY_DEFAULT
      %w(v1 v2).each do |api_version|
        %w(server secure_server verify).each do |url|
          instance_variable_set "@#{api_version}_#{url}_url", CONFIG[api_version][url]
        end
      end

      @private_key           = ENV['RECAPTCHA_PRIVATE_KEY']
      @public_key            = ENV['RECAPTCHA_PUBLIC_KEY']
    end

    def api_server_url(ssl = nil) #:nodoc:
      ssl = use_ssl_by_default if ssl.nil?
      ssl ? ssl_api_server_url : nonssl_api_server_url
    end

    def nonssl_api_server_url
      instance_variable_get "@#{@api_version}_server_url"
    end

    def ssl_api_server_url
      instance_variable_get "@#{@api_version}_secure_server_url"
    end

    def verify_url
      instance_variable_get "@#{@api_version}_verify_url"
    end

    def v1?
      @api_version == 'v1'
    end

    def v2?
      @api_version == 'v2'
    end
  end
end
