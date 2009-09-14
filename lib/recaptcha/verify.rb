module Recaptcha
  module Verify
    # Your private API can be specified in the +options+ hash or preferably
    # the environment variable +RECAPTCHA_PUBLIC_KEY+.
    def verify_recaptcha(options = {})
      return true if SKIP_VERIFY_ENV.include? ENV['RAILS_ENV']
      model = options.is_a?(Hash)? options[:model] : options
      private_key = options[:private_key] if options.is_a?(Hash)
      private_key ||= ENV['RECAPTCHA_PRIVATE_KEY']
      raise RecaptchaError, "No private key specified." unless private_key
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
        raise RecaptchaError, e
      end
    end # verify_recaptcha
  end # Verify
end # Recaptcha
