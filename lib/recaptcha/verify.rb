require 'json'

module Recaptcha
  module Verify
    # Your private API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def verify_recaptcha(options = {})
      options = {:model => options} unless options.is_a? Hash
      model = options[:model]
      attribute = options[:attribute] || :base

      return true if Recaptcha::Verify.skip?(options[:env])

      private_key = options[:private_key] || Recaptcha.configuration.private_key!
      recaptcha_response = options[:response] || params['g-recaptcha-response'].to_s
      custom_domain_validation = options[:domain] || nil

      begin
        # env['REMOTE_ADDR'] to retrieve IP for Grape API
        remote_ip = (request.respond_to?(:remote_ip) && request.remote_ip) || (env && env['REMOTE_ADDR'])
        verify_hash = {
          "secret"    => private_key,
          "remoteip"  => remote_ip.to_s,
          "response"  => recaptcha_response
        }

        raw_reply = Recaptcha.get(verify_hash, options)
        reply = JSON.parse(raw_reply)
        answer = reply['success']
        domain_validated = true

        if custom_domain_validation
          domain_validated = domain_validated?(reply['hostname'], custom_domain_validation)
        end

        if domain_validated && answer.to_s == 'true'
          flash.delete(:recaptcha_error) if recaptcha_flash_supported?
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
      verify_recaptcha(options) or raise VerifyError
    end

    private

    def domain_validated?(hostname, custom_domain_validation)
      if custom_domain_validation.respond_to?(:call)
        custom_domain_validation.call(hostname)
      elsif custom_domain_validation.respond_to?(:to_str)
        hostname == custom_domain_validation.to_str
      else
        raise ArgumentError, "Custom domain validation needs to be a string or a callable."
      end
    end

    def recaptcha_error(model, attribute, message, key, default)
      message = message || Recaptcha.i18n(key, default)
      flash[:recaptcha_error] = message if recaptcha_flash_supported?
      model.errors.add attribute, message if model
    end

    def recaptcha_flash_supported?
      request.respond_to?(:format) && request.format == :html && respond_to?(:flash)
    end

    def self.skip?(env)
      env ||= ENV['RACK_ENV'] || ENV['RAILS_ENV'] || (Rails.env if defined? Rails.env)
      Recaptcha.configuration.skip_verify_env.include? env
    end
  end
end
