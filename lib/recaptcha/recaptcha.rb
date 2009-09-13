# ReCAPTCHA
module Ambethia
  module ReCaptcha
    RECAPTCHA_API_SERVER        = 'http://api.recaptcha.net';
    RECAPTCHA_API_SECURE_SERVER = 'https://api-secure.recaptcha.net';
    RECAPTCHA_VERIFY_SERVER     = 'api-verify.recaptcha.net';

    SKIP_VERIFY_ENV = ['test', 'cucumber']

    module Helper
      # Your public API can be specified in the +options+ hash or preferably the environment
      # variable +RECAPTCHA_PUBLIC_KEY+.
      def recaptcha_tags(options = {})
        # Default options
        key   = options[:public_key] ||= ENV['RECAPTCHA_PUBLIC_KEY']
        error = options[:error] ||= session[:recaptcha_error]
        uri   = options[:ssl] ? RECAPTCHA_API_SECURE_SERVER : RECAPTCHA_API_SERVER
        html  = ""
        if options[:display]
          html << %{<script type="text/javascript">\n}
          html << %{  var RecaptchaOptions = #{options[:display].to_json};\n}
          html << %{</script>\n}
        end
        if options[:ajax]
          html << %{<div id="dynamic_recaptcha"></div>}
          html << %{<script type="text/javascript" src="#{uri}/js/recaptcha_ajax.js"></script>\n}
          html << %{<script type="text/javascript">\n}
          html << %{  Recaptcha.create('#{key}', document.getElementById('dynamic_recaptcha')#{options[:display] ? '' : ',RecaptchaOptions'});}
          html << %{</script>\n}
        else
          html << %{<script type="text/javascript" src="#{uri}/challenge?k=#{key}}
          html << %{#{error ? "&error=#{CGI::escape(error)}" : ""}"></script>\n}
          unless options[:noscript] == false
            html << %{<noscript>\n  }
            html << %{<iframe src="#{uri}/noscript?k=#{key}" }
            html << %{height="#{options[:iframe_height] ||= 300}" }
            html << %{width="#{options[:iframe_width]   ||= 500}" }
            html << %{frameborder="0"></iframe><br/>\n  }
            html << %{<textarea name="recaptcha_challenge_field" }
            html << %{rows="#{options[:textarea_rows] ||= 3}" }
            html << %{cols="#{options[:textarea_cols] ||= 40}"></textarea>\n  }
            html << %{<input type="hidden" name="recaptcha_response_field" value="manual_challenge">}
            html << %{</noscript>\n}
          end
        end
        raise ReCaptchaError, "No public key specified." unless key
        return html
      end # recaptcha_tags
    end # Helpers

    module Controller
      # Your private API can be specified in the +options+ hash or preferably the environment
      # variable +RECAPTCHA_PUBLIC_KEY+.
      def verify_recaptcha(options = {})
        return true if SKIP_VERIFY_ENV.include? ENV['RAILS_ENV']
        model = options.is_a?(Hash)? options[:model] : options
        private_key = options[:private_key] if options.is_a?(Hash) 
	private_key ||= ENV['RECAPTCHA_PRIVATE_KEY']
        raise ReCaptchaError, "No private key specified." unless private_key
        begin
          recaptcha = Net::HTTP.post_form URI.parse("http://#{RECAPTCHA_VERIFY_SERVER}/verify"), {
            "privatekey" => private_key,
            "remoteip"   => request.remote_ip,
            "challenge"  => params[:recaptcha_challenge_field],
            "response"   => params[:recaptcha_response_field]
          }
          answer, error = recaptcha.body.split.map { |s| s.chomp }
          unless answer == 'true'
            session[:recaptcha_error] = error
            if model
              model.valid?
              if Rails::VERSION::MAJOR == 2 and Rails::VERSION::MINOR >= 2
                model.errors.add :base, I18n.translate("#{model.class.name.underscore}.captcha", :scope => %w(errors models), :default => (options[:message] || "Captcha response is incorrect, please try again."))
              else
                model.errors.add :base, options[:message] || "Captcha response is incorrect, please try again."
              end
            end
            return false
          else
            session[:recaptcha_error] = nil
            return true
          end
        rescue Exception => e
          raise ReCaptchaError, e
        end
      end # verify_recaptcha
    end # ControllerHelpers

    class ReCaptchaError < StandardError; end

  end # ReCaptcha
end # Ambethia
