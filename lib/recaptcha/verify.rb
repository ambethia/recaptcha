require 'json'

module Recaptcha
  module Verify
    # Your private API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def verify_recaptcha(options = {})
      options = {model: options} unless options.is_a? Hash
      return true if Recaptcha::Verify.skip?(options[:env])

      model = options[:model]
      attribute = options[:attribute] || :base
      recaptcha_response = options[:response] || params['g-recaptcha-response'].to_s

      begin
        verified = if recaptcha_response.empty?
          false
        else
          recaptcha_verify_via_api_call(request, recaptcha_response, options)
        end

        if verified
          flash.delete(:recaptcha_error) if recaptcha_flash_supported? && !model
          true
        else
          recaptcha_error(
            model,
            attribute,
            options[:message],
            "recaptcha.errors.verification_failed",
            "reCAPTCHA verification failed, please try again."
          )
          false
        end
      rescue Timeout::Error
        if Recaptcha.configuration.handle_timeouts_gracefully
          recaptcha_error(
            model,
            attribute,
            options[:message],
            "recaptcha.errors.recaptcha_unreachable",
            "Oops, we failed to validate your reCAPTCHA response. Please try again."
          )
          false
        else
          raise RecaptchaError, "Recaptcha unreachable."
        end
      rescue StandardError => e
        raise RecaptchaError, e.message, e.backtrace
      end
    end

    def verify_recaptcha!(options = {})
      verify_recaptcha(options) || raise(VerifyError)
    end

    def self.skip?(env)
      env ||= ENV['RACK_ENV'] || ENV['RAILS_ENV'] || (Rails.env if defined? Rails.env)
      Recaptcha.configuration.skip_verify_env.include? env
    end

    private

    def recaptcha_verify_via_api_call(request, recaptcha_response, options)
      secret_key = options[:secret_key] || Recaptcha.configuration.secret_key!
      remote_ip = (request.respond_to?(:remote_ip) && request.remote_ip) || (env && env['REMOTE_ADDR'])

      verify_hash = {
        "secret"    => secret_key,
        "remoteip"  => remote_ip.to_s,
        "response"  => recaptcha_response
      }

      reply = JSON.parse(Recaptcha.get(verify_hash, options))
      reply['success'].to_s == "true" &&
        recaptcha_hostname_valid?(reply['hostname'], options[:hostname])
    end

    def recaptcha_hostname_valid?(hostname, validation)
      validation ||= Recaptcha.configuration.hostname

      case validation
      when nil, FalseClass then true
      when String then validation == hostname
      else validation.call(hostname)
      end
    end

    def recaptcha_error(model, attribute, message, key, default)
      message ||= Recaptcha.i18n(key, default)
      if model
        model.errors.add attribute, message
      else
        flash[:recaptcha_error] = message if recaptcha_flash_supported?
      end
    end

    def recaptcha_flash_supported?
      request.respond_to?(:format) && request.format == :html && respond_to?(:flash)
    end
  end
end
