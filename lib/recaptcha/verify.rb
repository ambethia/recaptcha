require "uri"
module Recaptcha
  module Verify
    # Your private API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def verify_recaptcha(options = {})
      options = {:model => options} unless options.is_a? Hash

      env_options = options[:env] || ENV['RAILS_ENV']
      return true if Recaptcha.configuration.skip_verify_env.include? env_options
      model = options[:model]
      attribute = options[:attribute] || :base
      private_key = options[:private_key] || Recaptcha.configuration.private_key
      raise RecaptchaError, "No private key specified." unless private_key

      begin
        recaptcha = nil
        if(Recaptcha.configuration.proxy)
          proxy_server = URI.parse(Recaptcha.configuration.proxy)
          http = Net::HTTP::Proxy(proxy_server.host, proxy_server.port, proxy_server.user, proxy_server.password)
        else
          http = Net::HTTP
        end

        # env['REMOTE_ADDR'] to retrieve IP for Grape API
        remote_ip = (request.respond_to?(:remote_ip) && request.remote_ip) || (env && env['REMOTE_ADDR'])
        if Recaptcha.configuration.v1?
          verify_hash = {
            "privatekey" => private_key,
            "remoteip"   => remote_ip,
            "challenge"  => params[:recaptcha_challenge_field],
            "response"   => params[:recaptcha_response_field]
          }
          Timeout::timeout(options[:timeout] || 3) do
            recaptcha = http.post_form(URI.parse(Recaptcha.configuration.verify_url), verify_hash)
          end
          answer, error = recaptcha.body.split.map { |s| s.chomp }
        end

        if Recaptcha.configuration.v2?
          verify_hash = {
            "secret"    => private_key,
            "remoteip"  => remote_ip,
            "response"  => params['g-recaptcha-response']
          }

          Timeout::timeout(options[:timeout] || 3) do
            uri = URI.parse(Recaptcha.configuration.verify_url + '?' + verify_hash.to_query)
            http_instance = http.new(uri.host, uri.port)
            if uri.port==443
              http_instance.use_ssl =
              http_instance.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
            request = Net::HTTP::Get.new(uri.request_uri)
            recaptcha = http_instance.request(request)
          end
          answer, error = JSON.parse(recaptcha.body).values
        end

        unless answer.to_s == 'true'
          error = 'verification_failed' if error && Recaptcha.configuration.v2?
          if request_in_html_format?
            flash[:recaptcha_error] = if defined?(I18n)
                                        I18n.translate("recaptcha.errors.#{error}", {:default => error})
                                      else
                                        error
                                      end
          end

          if model
            message = "Word verification response is incorrect, please try again."
            message = I18n.translate('recaptcha.errors.verification_failed', {:default => message}) if defined?(I18n)
            model.errors.add attribute, options[:message] || message
          end
          return false
        else
          flash.delete(:recaptcha_error) if request_in_html_format?
          return true
        end
      rescue Timeout::Error
        if Recaptcha.configuration.handle_timeouts_gracefully
          if request_in_html_format?
            flash[:recaptcha_error] = if defined?(I18n)
                                        I18n.translate('recaptcha.errors.recaptcha_unreachable', {:default => 'Recaptcha unreachable.'})
                                      else
                                        'Recaptcha unreachable.'
                                      end
          end

          if model
            message = "Oops, we failed to validate your word verification response. Please try again."
            message = I18n.translate('recaptcha.errors.recaptcha_unreachable', :default => message) if defined?(I18n)
            model.errors.add attribute, options[:message] || message
          end
          return false
        else
          raise RecaptchaError, "Recaptcha unreachable."
        end
      rescue Exception => e
        raise RecaptchaError, e.message, e.backtrace
      end
    end # verify_recaptcha

    def request_in_html_format?
      request.respond_to?(:format) && request.format == :html && respond_to?(:flash)
    end
    def verify_recaptcha!(options = {})
      verify_recaptcha(options) or raise VerifyError
    end #verify_recaptcha!
  end # Verify
end # Recaptcha
