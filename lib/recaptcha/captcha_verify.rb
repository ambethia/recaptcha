require "uri"
module Recaptcha
  module Verify
    # Used in Controller for Check Captcha data
    # Returned True if is Test env
    # Returned True if params has not :recaptcha_* fields
    # Raised RecaptchaVerifyError if the captcha is incorrect
    # Returned False otherwise
    def captcha_verify(options = {})
      return true unless recaptcha? 
      
      env = options[:env] || ENV['RAILS_ENV']
      return true if Recaptcha.configuration.skip_verify_env.include? env
      
      unless verify(options)
        raise RecaptchaVerifyError
      end
      false
    end 
    
    private
      #Returned true if valid re-captcha 
      #otherwise return false
      #Raised RecaptchaError on Timeout::Error
      def verify(options = {})
      
        private_key = options[:private_key] || Recaptcha.configuration.private_key
        raise RecaptchaError, "No private key specified." unless private_key
      
        post_request = {
          :privatekey => private_key,
          :remoteip   => request.remote_ip,
          :challenge  => params[:recaptcha_challenge_field],
          :response   => params[:recaptcha_response_field]
        }

        begin
          http = net_http
          url  = URI.parse(Recaptcha.configuration.verify_url)
          recaptcha = nil 
          Timeout::timeout(options[:timeout] || 3) do 
            recaptcha = http.post_form(url, post_request)
          end
        
          answer, error = recaptcha.body.split.map { |s| s.chomp }
          
          unless answer == 'true'
            flash[:recaptcha_error] = error
            return false
          end
        
        rescue Timeout::Error
          flash[:recaptcha_error] = 'Recaptcha unreachable.'
          return false
        rescue Exception => e
          raise RecaptchaError, e.message, e.backtrace
        end
      
        return true
      end
      

      def recaptcha? #:nodoc: 
        return false unless params[:recaptcha_challenge_field] &&
                   params[:recaptcha_response_field]
        true            
      end 

      def net_http #:nodoc:
        return Net::HTTP unless Recaptcha.configuration.proxy
        
        proxy_server = URI.parse(Recaptcha.configuration.proxy)
        http = Net::HTTP::Proxy(proxy_server.host, proxy_server.port, proxy_server.user, proxy_server.password)
      end 
  end  
end 
