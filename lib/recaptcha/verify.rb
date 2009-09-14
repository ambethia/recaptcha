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
        recaptcha = nil
        Timeout::timeout(options[:timeout] || 3) do
          recaptcha = Net::HTTP.post_form URI.parse("http://#{RECAPTCHA_VERIFY_SERVER}/verify"), {
            "privatekey" => private_key,
            "remoteip"   => request.remote_ip,
            "challenge"  => params[:recaptcha_challenge_field],
            "response"   => params[:recaptcha_response_field]
          }
        end
        answer, error = recaptcha.body.split.map { |s| s.chomp }
        unless answer == 'true'
          session[:recaptcha_error] = error
          if model
            model.valid?
            model.errors.add :base, options[:message] || "Captcha response is incorrect, please try again."
          end
          return false
        else
          session[:recaptcha_error] = nil
          return true
        end
      rescue Timeout::Error 
        session[:recaptcha_error] = "recaptcha-not-reachable"
        if model
          model.valid?
          model.errors.add :base, options[:message] || "Oops, we failed to validate your Captcha. Please try again."
        end
        return false
      rescue Exception => e
        raise RecaptchaError, e.message, e.backtrace
      end
    end # verify_recaptcha
  end # Verify
end # Recaptcha
