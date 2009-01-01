# ReCAPTCHA
module Ambethia
  module ReCaptcha
    RECAPTCHA_API_SERVER        = 'http://api.recaptcha.net';
    RECAPTCHA_API_SECURE_SERVER = 'https://api-secure.recaptcha.net';
    RECAPTCHA_VERIFY_SERVER     = 'api-verify.recaptcha.net';

    SKIP_VERIFY_ENV = ['test']

    module Helper
      # Your public API can be specified in the +options+ hash or preferably the environment
      # variable +RECAPTCHA_PUBLIC_KEY+.
      def recaptcha_tags(options = {})
        # Default options
        key   = options[:public_key] ||= ENV['RECAPTCHA_PUBLIC_KEY']
        error = options[:error] ||= session[:recaptcha_error]
        uri   = options[:ssl] ? RECAPTCHA_API_SECURE_SERVER : RECAPTCHA_API_SERVER
        xhtml = Builder::XmlMarkup.new :target => out=(''), :indent => 2 # Because I can.
        if options[:display]
          xhtml.script(:type => "text/javascript"){ |x| x << "var RecaptchaOptions = #{options[:display].to_json};\n"}
        end
        if options[:ajax]
         xhtml.div(:id => 'dynamic_recaptcha') {}
         xhtml.script(:type => "text/javascript", :src => "#{uri}/js/recaptcha_ajax.js") {}
         xhtml.script(:type => "text/javascript") do |x|
           x << "Recaptcha.create('#{key}', document.getElementById('dynamic_recaptcha') );"
         end
        else
          xhtml.script(:type => "text/javascript", :src => :"#{uri}/challenge?k=#{key}&error=#{error}") {}
          unless options[:noscript] == false
            xhtml.noscript do
              xhtml.iframe(:src    => "#{uri}/noscript?k=#{key}",
                           :height => options[:iframe_height] ||= 300,
                           :width  => options[:iframe_width]  ||= 500,
                           :frameborder => 0) {}; xhtml.br
              xhtml.textarea nil, :name => "recaptcha_challenge_field",
                                  :rows => options[:textarea_rows] ||= 3,
                                  :cols => options[:textarea_cols] ||= 40
              xhtml.input :name => "recaptcha_response_field",
                          :type => "hidden", :value => "manual_challenge"
            end
          end
        end
        raise ReCaptchaError, "No public key specified." unless key
        return out
      end # recaptcha_tags
    end # Helpers

    module Controller
      # Your private API can be specified in the +options+ hash or preferably the environment
      # variable +RECAPTCHA_PUBLIC_KEY+.
      def verify_recaptcha(options = {})
        return true if SKIP_VERIFY_ENV.include? ENV['RAILS_ENV']
        private_key = options[:private_key] ||= ENV['RECAPTCHA_PRIVATE_KEY']
        raise ReCaptchaError, "No private key specified." unless private_key
        begin
          recaptcha = Net::HTTP.post_form URI.parse("http://#{RECAPTCHA_VERIFY_SERVER}/verify"), {
            :privatekey => private_key,
            :remoteip   => request.remote_ip,
            :challenge  => params[:recaptcha_challenge_field],
            :response   => params[:recaptcha_response_field]
          }
          answer, error = recaptcha.body.split.map { |s| s.chomp }
          unless answer == 'true'
            session[:recaptcha_error] = error
            if model = options[:model]
              model.valid?
              model.errors.add_to_base "Captcha response is incorrect, please try again."
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
