module Recaptcha
  module ClientHelper
    # Your public API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def recaptcha_tags(options = {})
      return v1_tags(options) if Recaptcha.configuration.v1?
      return v2_tags(options) if Recaptcha.configuration.v2?
    end # recaptcha_tags

    def v1_tags(options)
      # Default options
      key   = options[:public_key] ||= Recaptcha.configuration.public_key
      raise RecaptchaError, "No public key specified." unless key
      error = options[:error] ||= ((defined? flash) ? flash[:recaptcha_error] : "")
      uri   = Recaptcha.configuration.api_server_url(options[:ssl])
      lang  = options[:display] && options[:display][:lang] ? options[:display][:lang].to_sym : ""
      html  = ""
      if options[:display]
        html << %{<script type="text/javascript">\n}
        html << %{  var RecaptchaOptions = #{hash_to_json(options[:display])};\n}
        html << %{</script>\n}
      end
      if options[:ajax]
        if options[:display] && options[:display][:custom_theme_widget]
          widget = options[:display][:custom_theme_widget]
        else
          widget = "dynamic_recaptcha"
          html << <<-EOS
           <div id="#{widget}"></div>
          EOS
        end
        html << <<-EOS
          <script type="text/javascript">
            var rc_script_tag = document.createElement('script'),
                rc_init_func = function(){Recaptcha.create("#{key}", document.getElementById("#{widget}")#{',RecaptchaOptions' if options[:display]});}
            rc_script_tag.src = "#{uri}/js/recaptcha_ajax.js";
            rc_script_tag.type = 'text/javascript';
            rc_script_tag.onload = function(){rc_init_func.call();};
            rc_script_tag.onreadystatechange = function(){
              if (rc_script_tag.readyState == 'loaded' || rc_script_tag.readyState == 'complete') {rc_init_func.call();}
            };
            (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(rc_script_tag);
          </script>
        EOS
      else
        html << %{<script type="text/javascript" src="#{uri}/challenge?k=#{key}}
        html << %{#{error ? "&amp;error=#{CGI::escape(error)}" : ""}}
        html << %{#{lang ? "&amp;lang=#{lang}" : ""}"></script>\n}
        unless options[:noscript] == false
          html << %{<noscript>\n  }
          html << %{<iframe src="#{uri}/noscript?k=#{key}" }
          html << %{height="#{options[:iframe_height] ||= 300}" }
          html << %{width="#{options[:iframe_width]   ||= 500}" }
          html << %{style="border:none;"></iframe><br/>\n  }
          html << %{<textarea name="recaptcha_challenge_field" }
          html << %{rows="#{options[:textarea_rows] ||= 3}" }
          html << %{cols="#{options[:textarea_cols] ||= 40}"></textarea>\n  }
          html << %{<input type="hidden" name="recaptcha_response_field" value="manual_challenge"/>}
          html << %{</noscript>\n}
        end
      end
      return (html.respond_to?(:html_safe) && html.html_safe) || html
    end

    def v2_tags(options)
      public_key   = options[:public_key] ||= Recaptcha.configuration.public_key
      raise RecaptchaError, "No public key specified." unless public_key
      private_key  = options[:private_key] ||= Recaptcha.configuration.private_key
      raise RecaptchaError, "No private key specified." unless private_key
      error = options[:error] ||= ((defined? flash) ? flash[:recaptcha_error] : "")
      uri   = Recaptcha.configuration.api_server_url(options[:ssl])
      uri += "?hl=#{options[:hl]}" unless options[:hl].blank?

      v2_options = options.slice(:theme, :type, :callback, :expired_callback).map {|k,v| %{data-#{k.to_s.gsub(/_/,'-')}="#{v}"} }.join(" ")

      stoken_json = hash_to_json({'session_id' => SecureRandom.uuid, 'ts_ms' => (Time.now.to_f * 1000).to_i})
      cipher = OpenSSL::Cipher::AES128.new(:ECB)
      private_key_digest = Digest::SHA1.digest(private_key)[0...16]

      cipher.encrypt
      cipher.key = private_key_digest
      encrypted_stoken = cipher.update(stoken_json) << cipher.final
      encoded_stoken = Base64.urlsafe_encode64(encrypted_stoken).gsub(/\=+\Z/, '')

      html = ""
      html << %{<script src="#{uri}" async defer></script>\n}
      if options[:stoken] == false
        html << %{<div class="g-recaptcha" data-sitekey="#{public_key}" #{v2_options}></div>\n}
      else
        html << %{<div class="g-recaptcha" data-sitekey="#{public_key}" data-stoken="#{encoded_stoken}" #{v2_options}></div>\n}
      end

      unless options[:noscript] == false
        fallback_uri = "#{uri.chomp('.js')}/fallback?k=#{public_key}"
        html << %{<noscript>}
        html << %{<div style="width: 302px; height: 352px;">}
        html << %{  <div style="width: 302px; height: 352px; position: relative;">}
        html << %{    <div style="width: 302px; height: 352px; position: absolute;">}
        html << %{      <iframe src="#{fallback_uri}"}
        html << %{                frameborder="0" scrolling="no"}
        html << %{                style="width: 302px; height:352px; border-style: none;">}
        html << %{        </iframe>}
        html << %{      </div>}
        html << %{      <div style="width: 250px; height: 80px; position: absolute; border-style: none; }
        html << %{             bottom: 21px; left: 25px; margin: 0px; padding: 0px; right: 25px;">}
        html << %{        <textarea id="g-recaptcha-response" name="g-recaptcha-response" }
        html << %{                  class="g-recaptcha-response" }
        html << %{                  style="width: 250px; height: 80px; border: 1px solid #c1c1c1; }
        html << %{                  margin: 0px; padding: 0px; resize: none;" value=""> }
        html << %{        </textarea>}
        html << %{      </div>}
        html << %{    </div>}
        html << %{  </div>}
        html << %{</noscript>}
      end

      return (html.respond_to?(:html_safe) && html.html_safe) || html
    end

    private

    def hash_to_json(hash)
      result = "{"
      result << hash.map do |k, v|
        if v.is_a?(Hash)
          "\"#{k}\": #{hash_to_json(v)}"
        elsif ! v.is_a?(String) || k.to_s =~ %r{(callback|expired-callback)}
          "\"#{k}\": #{v}"
        else
          "\"#{k}\": \"#{v}\""
        end
      end.join(", ")
      result << "}"
    end
  end # ClientHelper
end # Recaptcha
