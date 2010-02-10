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
    attr_accessor :nonssl_api_server_url,
                  :ssl_api_server_url,
                  :verify_url,
                  :skip_verify_env,
                  :private_key,
                  :public_key

    def initialize #:nodoc:
      @nonssl_api_server_url = RECAPTCHA_API_SERVER_URL
      @ssl_api_server_url    = RECAPTCHA_API_SECURE_SERVER_URL
      @verify_url            = RECAPTCHA_VERIFY_URL
      @skip_verify_env       = SKIP_VERIFY_ENV

      @private_key           = ENV['RECAPTCHA_PRIVATE_KEY']
      @public_key            = ENV['RECAPTCHA_PUBLIC_KEY']
    end

    def api_server_url(ssl = false) #:nodoc:
      ssl ? ssl_api_server_url : nonssl_api_server_url
    end
  end
end
