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

      begin
        # env['REMOTE_ADDR'] to retrieve IP for Grape API
        remote_ip = (request.respond_to?(:remote_ip) && request.remote_ip) || (env && env['REMOTE_ADDR'])
        verify_hash = {
          "secret"    => private_key,
          "remoteip"  => remote_ip.to_s,
          "response"  => params['g-recaptcha-response'].to_s
        }

        reply = Recaptcha.get(verify_hash, options)
        answer = JSON.parse(reply)['success']

        if answer.to_s == 'true'
          flash.delete(:recaptcha_error) if recaptcha_flash_supported?
          true
        else
          recaptcha_error(
            model,
            attribute,
            options[:message],
            "recaptcha.errors.verification_failed",
            "Word verification response is incorrect, please try again."
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
            "Oops, we failed to validate your word verification response. Please try again."
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

    def recaptcha_error(model, attribute, message, key, default)
      message = message || Recaptcha.i18n(key, default)
      flash[:recaptcha_error] = message if recaptcha_flash_supported?
      model.errors.add attribute, message if model
    end

    def recaptcha_flash_supported?
      request.respond_to?(:format) && request.format == :html && respond_to?(:flash)
    end

    def self.skip?(env)
      env ||= ENV['RAILS_ENV'] || (Rails.env if defined? Rails.env)
      Recaptcha.configuration.skip_verify_env.include? env
    end
  end
end
