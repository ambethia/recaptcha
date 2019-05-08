# frozen_string_literal: true

module Recaptcha
  module Adapters
    module Controller
      # Your private API can be specified in the +options+ hash or preferably
      # using the Configuration.
      def verify_recaptcha(options = {})
        options = {model: options} unless options.is_a? Hash
        return true if ::Recaptcha::Verify.skip?(options[:env])

        model = options[:model]
        attribute = options[:attribute] || :base
        recaptcha_response = options[:response] || params['g-recaptcha-response'].to_s

        begin
          verified = if ::Recaptcha::Verify.invalid_response?(recaptcha_response)
            false
          else
            unless options[:skip_remote_ip]
              remoteip = (request.respond_to?(:remote_ip) && request.remote_ip) || (env && env['REMOTE_ADDR'])
              options = options.merge(remote_ip: remoteip.to_s) if remoteip
            end

            ::Recaptcha::Verify.verify_via_api_call(recaptcha_response, options)
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
end
