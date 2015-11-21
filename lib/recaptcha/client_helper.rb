module Recaptcha
  module ClientHelper
    # Your public API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def recaptcha_tags(options = {})
      public_key   = options[:public_key] ||= Recaptcha.configuration.public_key
      raise RecaptchaError, "No public key specified." unless public_key
      private_key  = options[:private_key] ||= Recaptcha.configuration.private_key
      raise RecaptchaError, "No private key specified." unless private_key
      error = options[:error] ||= ((defined? flash) ? flash[:recaptcha_error] : "") # TODO not being used !?
      uri   = Recaptcha.configuration.api_server_url(ssl: options[:ssl])
      uri += "?hl=#{options[:hl]}" unless options[:hl].blank?

      html = ""
      html << %{<script src="#{uri}" async defer></script>\n}

      data_attributes = options.slice(:theme, :type, :callback, :expired_callback, :size)
      data_attributes[:sitekey] = public_key

      if options[:stoken] != false
        data_attributes[:stoken] = Recaptcha::Token.secure_token
      end

      data_attributes = data_attributes.map {|k,v| %{data-#{k.to_s.gsub(/_/,'-')}="#{v}"} }.join(" ")

      html << %{<div class="g-recaptcha" #{data_attributes}></div>\n}

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

      (html.respond_to?(:html_safe) && html.html_safe) || html
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
  end
end
