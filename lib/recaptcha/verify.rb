module Recaptcha
  module Verify
    # Your private API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def verify_recaptcha(options = {})
      if !options.is_a? Hash
        options = {:model => options}
      end
      
      env = options[:env] || ENV['RAILS_ENV']
      return true if Recaptcha.configuration.skip_verify_env.include? env
      model = options[:model]
      attribute = options[:attribute] || :base
      private_key = options[:private_key] || Recaptcha.configuration.private_key
      raise RecaptchaError, "No private key specified." unless private_key
      
      begin
        recaptcha = nil
        Timeout::timeout(options[:timeout] || 3) do
          recaptcha = Net::HTTP.post_form URI.parse(Recaptcha.configuration.verify_url), {
            "privatekey" => private_key,
            "remoteip"   => remote_ip,
            "challenge"  => recaptcha_challenge_field,
            "response"   => recaptcha_response_field
          }
        end
        answer, error = recaptcha.body.split.map { |s| s.chomp }
        unless answer == 'true'
          if model
            model.errors.add attribute, options[:message] || "Word verification response is incorrect, please try again."
          end
          return false
        else
          return true
        end
      rescue Timeout::Error 
        if model
          model.errors.add attribute, options[:message] || "Oops, we failed to validate your word verification response. Please try again."
        end
        return false
      rescue Exception => e
        raise RecaptchaError, e.message, e.backtrace
      end
    end # verify_recaptcha
  end # Verify
end # Recaptcha
