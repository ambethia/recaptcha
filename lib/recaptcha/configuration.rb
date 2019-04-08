# frozen_string_literal: true

require 'logger'

module Recaptcha
  # This class enables detailed configuration of the Recaptcha services.
  #
  # You can configure Recaptcha by updating `Recaptcha.configuration` directly:
  #
  # ```ruby
  #   Recaptcha.configuration # => instance of Recaptcha::Configuration
  # ```
  #
  # or by using a `Recaptcha.configure` block:
  #
  # ```ruby
  #   Recaptcha.configure do |config|
  #     config # => instance of Recaptcha::Configuration
  #   end
  # ```
  #
  # Your are able to customize all attributes listed below. Some attributes like `verify_url`
  # usually do not need to be changed.
  #
  # The site key and secret key have no useful default value so you _must_ configure them in one of the following ways.
  # - via `RECAPTCHA_SITE_KEY` and `RECAPTCHA_SECRET_KEY` enviroment variables
  # - by setting `config.site_key` and `config.secret_key` directly
  #
  # Values within this configuration take precedence over values from environment variables. It is
  # also possible to override this configuration via the `options` hash passed to specific methods
  # like {Recaptcha::Verify#verify_recaptcha_v2}.
  #
  # Setting the keys with this Configuration:
  #
  # ```ruby
  #   Recaptcha.configure do |config|
  #     config.site_key   = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'
  #     config.secret_key = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
  #   end
  # ```
  #
  # If you only intend to use one of the API versions, that's all you have to do. If you would like
  # to use both v2 and v3 APIs—or both a v2 checkbox and an invisible captcha—, then you need a
  # different key for each. You can configure multiple keys like this:
  #
  # ```ruby
  #   Recaptcha.configure do |config|
  #     config.site_key_v2_checkbox    = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyc'
  #     config.secret_key_v2_checkbox  = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxc'
  #     config.site_key_v2_invisible   = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyi'
  #     config.secret_key_v2_invisible = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxi'
  #     config.site_key_v3             = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyy3'
  #     config.secret_key_v3           = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxx3'
  #   end
  # ```
  #
  # and the helpers will automatically use the correct key. (In the backend, you will need to use
  # `verify_recaptcha_v2_checkbox` and `verify_recaptcha_v2_invisible` instead of simply
  # `verify_recaptcha` in order for it to know which key to use.)
  #
  # v3 is not simply a replacement for v2; they each have different use cases. Read [Should I use
  # reCAPTCHA v2 or v3?](https://developers.google.com/recaptcha/docs/faq#should-i-use-recaptcha-v2-or-v3).
  #
  class Configuration
    attr_accessor :skip_verify_env, :proxy, :handle_timeouts_gracefully, :hostname, :logger

    # Used to identify your site to the reCAPTCHA script that runs in your frontend code
    attr_accessor :site_key

    # Used to verify a response token against the reCAPTCHA API in your controller
    attr_accessor :secret_key

    attr_accessor \
      :site_key_v2_checkbox, :secret_key_v2_checkbox,
      :site_key_v2_invisible, :secret_key_v2_invisible,
      :site_key_v3, :secret_key_v3
    attr_writer :api_server_url, :verify_url

    def initialize
      @skip_verify_env = %w[test cucumber]
      @handle_timeouts_gracefully = HANDLE_TIMEOUTS_GRACEFULLY

      @site_key                = ENV['RECAPTCHA_SITE_KEY']
      @secret_key              = ENV['RECAPTCHA_SECRET_KEY']
      @site_key_v2_checkbox    = ENV['RECAPTCHA_SITE_KEY_V2_CHECKBOX']
      @secret_key_v2_checkbox  = ENV['RECAPTCHA_SECRET_KEY_V2_CHECKBOX']
      @site_key_v2_invisible   = ENV['RECAPTCHA_SITE_KEY_V2_INVISIBLE']
      @secret_key_v2_invisible = ENV['RECAPTCHA_SECRET_KEY_V2_INVISIBLE']
      @site_key_v3             = ENV['RECAPTCHA_SITE_KEY_V3']
      @secret_key_v3           = ENV['RECAPTCHA_SECRET_KEY_V3']

      @verify_url = nil
      @api_server_url = nil
      @logger = Logger.new('/dev/null')
    end

    def site_key!
      site_key || raise(RecaptchaError, "No site key specified.")
    end

    def site_key_v2_checkbox!
      site_key_v2_checkbox || site_key || raise(RecaptchaError, "No site key specified.")
    end

    def site_key_v2_invisible!
      site_key_v2_invisible || site_key || raise(RecaptchaError, "No site key specified.")
    end

    def site_key_v3!
      site_key_v3 || site_key || raise(RecaptchaError, "No site key specified.")
    end

    def secret_key!
      secret_key || raise(RecaptchaError, "No secret key specified.")
    end

    def secret_key_v2_checkbox!
      secret_key_v2_checkbox || secret_key || raise(RecaptchaError, "No secret key specified.")
    end

    def secret_key_v2_invisible!
      secret_key_v2_invisible || secret_key || raise(RecaptchaError, "No secret key specified.")
    end

    def secret_key_v3!
      secret_key_v3 || secret_key || raise(RecaptchaError, "No secret key specified.")
    end

    def api_server_url
      @api_server_url || CONFIG.fetch('server_url')
    end

    def verify_url
      @verify_url || CONFIG.fetch('verify_url')
    end
  end
end
