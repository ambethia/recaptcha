# frozen_string_literal: true

require 'json'
require 'recaptcha/verify/response'
require 'recaptcha/verify/result'

module Recaptcha
  module Verify
    class << self
      def get(request_hash, options)
        recaptcha_logger.debug %(Calling Recaptcha::Verify.get(#{request_hash.inspect}))
        http = if Recaptcha.configuration.proxy
          proxy_server = URI.parse(Recaptcha.configuration.proxy)
          Net::HTTP::Proxy(proxy_server.host, proxy_server.port, proxy_server.user, proxy_server.password)
        else
          Net::HTTP
        end
        query = URI.encode_www_form(request_hash)
        uri = URI.parse(Recaptcha.configuration.verify_url + '?' + query)
        http_instance = http.new(uri.host, uri.port)
        http_instance.read_timeout = http_instance.open_timeout = options[:timeout] || DEFAULT_TIMEOUT
        http_instance.use_ssl = true if uri.port == 443
        request = Net::HTTP::Get.new(uri.request_uri)
        http_response = http_instance.request(request)
        response = Response.new(http_response)
        recaptcha_logger.debug %(Response JSON: #{response.json})
        response
      end

      def recaptcha_logger
        Recaptcha.configuration.logger
      end
    end

    G_RESPONSE_LIMIT = 4000

    attr_reader :recaptcha_verify_result

    # Verifies a response token using the [reCAPTCHA v2
    # API](https://developers.google.com/recaptcha/docs/verify)
    #
    # @return [Boolean] `true` if it was able to successfully verify the response token, otherwise
    #   `false`. If this is `false`, you can check `@recaptcha_verify_result.errors` to see why it
    #   failed, or `@recaptcha_verify_result.response` to get access to the response from reCAPTCHA
    #   (see {Recaptcha::Verify::Result}).
    def verify_recaptcha_v2(options = {})
      options = {model: options} unless options.is_a? Hash
      response_token = options[:response] || params['g-recaptcha-response'].to_s

      _verify_recaptcha(:v2, response_token, options.freeze) do
        response = recaptcha_verify_via_api_v2_call(request, response_token, options)
        build_result(response, options)
      end
    end
    alias_method :verify_recaptcha, :verify_recaptcha_v2

    # This is the backend counterpart to the {Recaptcha::ClientHelper#recaptcha_v2_checkbox} view
    # helper.
    #
    # Verifies a response token using the [reCAPTCHA v2
    # API](https://developers.google.com/recaptcha/docs/verify) and the
    # {Recaptcha::Configuration#secret_key_v2_checkbox config.secret_key_v2_checkbox} secret key.
    #
    # @return (see #verify_recaptcha_v2)
    def verify_recaptcha_v2_checkbox(options = {})
      options = {model: options} unless options.is_a? Hash
      options[:secret_key] ||= Recaptcha.configuration.secret_key_v2_checkbox!
      verify_recaptcha_v2(options)
    end

    # @return (see #verify_recaptcha_v2)
    def verify_recaptcha_v2_invisible(options = {})
      options = {model: options} unless options.is_a? Hash
      options[:secret_key] ||= Recaptcha.configuration.secret_key_v2_invisible!
      verify_recaptcha_v2(options)
    end

    # Same as {#verify_recaptcha_v2} but raises an error if there is any failure to verify the
    # response token and validate the response (including if the hostname didn't match).
    #
    # @return (see #verify_recaptcha_v2)
    def verify_recaptcha_v2!(options = {})
      verify_recaptcha(options) || raise(VerifyError)
    end
    alias_method :verify_recaptcha!, :verify_recaptcha_v2!

    # Verifies a response token using the [reCAPTCHA v3
    # API](https://developers.google.com/recaptcha/docs/v3), which returns a score for the given
    # request/action without user friction.
    #
    # Unlike the v2 API, the reCAPTCHA v3 API is not binary (is not simplify verified/success or
    # not). The v3 API returns a score, so rather than returning a boolean like
    # `verify_recaptcha_v2` does, `verify_recaptcha_v3` returns a `Verify::Result` which has a `score`
    # method on it. The `Verify::Result` object also gives you access to `error_codes` and anything
    # else returned in the [API
    # response](https://developers.google.com/recaptcha/docs/v3#site-verify-response).
    #
    # @return [Recaptcha::Verify::Result, Boolean] The result of verification, including the `score`.
    #   or `error_codes`.
    def verify_recaptcha_v3(options = {})
      options.key?(:action) || raise(Recaptcha::RecaptchaError, 'action is required')
      action = options[:action]
      response_token = options[:response] || get_response_token_for_action(action)

      _verify_recaptcha(:v3, response_token, options.freeze) do
        response = recaptcha_verify_via_api_v3_call(request, response_token, options)
        build_result(response, options)
      end
    end

    # rubocop:disable Style/SafeNavigation

    # Same as {#verify_recaptcha_v3} but raises an error if there is any failure (_including_ if no
    # response token was submitted/found).
    # @return (see #verify_recaptcha_v3)
    def verify_recaptcha_v3!(options = {})
      result = verify_recaptcha_v3(options)
      # result could be false or a Verify::Result
      unless result && result.valid?
        if @recaptcha_verify_result
          raise(VerifyError, @recaptcha_verify_result.errors.to_sentence)
        else
          raise(VerifyError)
        end
      end
      result
    end

    # rubocop:enable Style/SafeNavigation

    # Returns true if the given enviroment should be skipped according to
    # {Recaptcha::Configuration#skip_verify_env config.skip_verify_env}.
    def self.skip?(env)
      env ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || (Rails.env if defined? Rails.env)
      Recaptcha.configuration.skip_verify_env.include? env
    end

    private

    # Handles per-env skip, error handling, flash.
    # @return [Recaptcha::Verify::Result, Boolean] The result of verification as a
    # Verify::Result for v3, or as a boolean for v2.
    def _verify_recaptcha(version, response_token, options = {})
      return true if Recaptcha::Verify.skip?(options[:env])

      model = options[:model]
      attribute = options[:attribute] || :base

      result_or_boolean = ->(result, boolean) {
        @recaptcha_verify_result = result
        if version == :v3
          result
        else
          boolean
        end
      }

      begin
        result = (
          if response_token.empty?
            MissingResponseTokenErrorResult.new
          elsif response_token.length > G_RESPONSE_LIMIT
            ResponseTokenTooLongErrorResult.new(response_token.length)
          else
            yield
          end
        )

        if result.valid?
          recaptcha_logger.debug "Result: valid"
          flash.delete(:recaptcha_error) if recaptcha_flash_supported? && !model
          result_or_boolean.call(result, true)
        else
          recaptcha_logger.warn "Result: errors: #{result.errors}"
          recaptcha_error(
            model,
            attribute,
            options[:message],
            "recaptcha.errors.verification_failed",
            "reCAPTCHA verification failed, please try again."
          )
          result_or_boolean.call(result, false)
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
          result = TimeoutErrorResult.new
          result_or_boolean.call(result, false)
        else
          raise RecaptchaError, "Recaptcha unreachable."
        end
      rescue StandardError => e
        raise RecaptchaError, e.message, e.backtrace
      end
    end

    # @return [Recaptcha::Verify::Response]
    def recaptcha_verify_via_api_v2_call(request, response_token, options)
      secret_key = options[:secret_key] || Recaptcha.configuration.secret_key_v2_checkbox!
      recaptcha_verify_via_api_call(request, response_token, secret_key, options)
    end

    # @return [Recaptcha::Verify::Response]
    def recaptcha_verify_via_api_v3_call(request, response_token, options)
      secret_key = options[:secret_key] || Recaptcha.configuration.secret_key_v3!
      recaptcha_verify_via_api_call(request, response_token, secret_key, options)
    end

    # @return [Recaptcha::Verify::Response]
    def recaptcha_verify_via_api_call(request, response_token, secret_key, options)
      request_hash = {
        "secret" => secret_key,
        "response" => response_token
      }

      unless options[:skip_remote_ip]
        remoteip = (request.respond_to?(:remote_ip) && request.remote_ip) || (env && env['REMOTE_ADDR'])
        request_hash["remoteip"] = remoteip.to_s
      end

      Recaptcha::Verify.get(request_hash, options)
    end

    def build_result(response, options)
      Verify::Result.new(
        response,
        expected_hostname: options[:hostname],
        expected_action: options[:action],
        minimum_score: options[:minimum_score]
      )
    end

    # Expects params['g-recaptcha-response'] to be a hash with the action name(s) as keys, but also
    # works if a single response token is passed as a value instead of a hash.
    # @return [String] A response token if one was passed in the params; otherwise, `''`
    def get_response_token_for_action(action)
      response_param = params['g-recaptcha-response']
      if response_param&.respond_to?(:to_h) # Includes ActionController::Parameters
        response_param[action]&.to_s
      else
        response_param.to_s
      end
    end

    # If model is present, adds the error to `model`; otherwise, if flash supported, sets
    # flash[:recaptcha_error]
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

    def recaptcha_logger
      Recaptcha.configuration.logger
    end

    class VerifyError < Recaptcha::RecaptchaError
    end
  end
end
