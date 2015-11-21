require "uri"
require "json"
require "active_support/core_ext/object/to_query"

module Recaptcha
  module Verify
    DEFAULT_TIMEOUT = 3

    # Your private API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def verify_recaptcha(options = {})
      options = {:model => options} unless options.is_a? Hash
      model = options[:model]
      attribute = options[:attribute] || :base

      env_options = options[:env] || ENV['RAILS_ENV'] || (Rails.env if defined? Rails.env)
      return true if Recaptcha.configuration.skip_verify_env.include? env_options

      private_key = options[:private_key] || Recaptcha.configuration.private_key
      raise RecaptchaError, "No private key specified." unless private_key

      begin
        # env['REMOTE_ADDR'] to retrieve IP for Grape API
        remote_ip = (request.respond_to?(:remote_ip) && request.remote_ip) || (env && env['REMOTE_ADDR'])
        verify_hash = {
          "secret"    => private_key,
          "remoteip"  => remote_ip,
          "response"  => params['g-recaptcha-response']
        }

        reply = Timeout::timeout(options[:timeout] || DEFAULT_TIMEOUT) do
          http = if Recaptcha.configuration.proxy
            proxy_server = URI.parse(Recaptcha.configuration.proxy)
            Net::HTTP::Proxy(proxy_server.host, proxy_server.port, proxy_server.user, proxy_server.password)
          else
            Net::HTTP
          end
          uri = URI.parse(Recaptcha.configuration.verify_url + '?' + verify_hash.to_query)
          http_instance = http.new(uri.host, uri.port)
          if uri.port == 443
            http_instance.use_ssl = true
            http_instance.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          request = Net::HTTP::Get.new(uri.request_uri)
          http_instance.request(request).body
        end

        answer = JSON.parse(reply).values.first

        if answer.to_s == 'true'
          flash.delete(:recaptcha_error) if recaptcha_flash_supported?
          true
        else
          message = options[:message] || recaptcha_i18n(
            "recaptcha.errors.verification_failed",
            "Word verification response is incorrect, please try again."
          )

          flash[:recaptcha_error] = message if recaptcha_flash_supported?
          model.errors.add attribute, message if model

          false
        end
      rescue Timeout::Error
        if Recaptcha.configuration.handle_timeouts_gracefully
          message = options[:message] || recaptcha_i18n(
            "recaptcha.errors.recaptcha_unreachable",
            "Oops, we failed to validate your word verification response. Please try again."
          )

          flash[:recaptcha_error] = message if recaptcha_flash_supported?
          model.errors.add attribute, message if model

          false
        else
          raise RecaptchaError, "Recaptcha unreachable."
        end
      rescue StandardError => e
        raise RecaptchaError, e.message, e.backtrace
      end
    end

    def recaptcha_i18n(key, default)
      if defined?(I18n)
        I18n.translate(key, default: default)
      else
        default
      end
    end

    def recaptcha_flash_supported?
      request.respond_to?(:format) && request.format == :html && respond_to?(:flash)
    end

    def verify_recaptcha!(options = {})
      verify_recaptcha(options) or raise VerifyError
    end
  end
end
