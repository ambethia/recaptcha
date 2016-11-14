module Recaptcha
  module ClientHelper
    # Your public API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def recaptcha_tags(options = {})
      if options.key?(:stoken)
        raise(RecaptchaError, "Secure Token is deprecated. Please remove 'stoken' from your calls to recaptcha_tags.")
      end
      if options.key?(:ssl)
        raise(RecaptchaError, "SSL is now always true. Please remove 'ssl' from your calls to recaptcha_tags.")
      end

      site_key = options[:site_key] || Recaptcha.configuration.site_key!

      script_url = Recaptcha.configuration.api_server_url
      script_url += "?hl=#{options[:hl]}" unless options[:hl].to_s == ""
      fallback_uri = "#{script_url.chomp('.js')}/fallback?k=#{site_key}"

      data_attributes = [:theme, :type, :callback, :expired_callback, :size]
      data_attributes = options.each_with_object({}) do |(k, v), a|
        a[k] = v if data_attributes.include?(k)
      end
      data_attributes[:sitekey] = site_key
      tag_attributes = data_attributes.map { |k, v| %(data-#{k.to_s.tr('_', '-')}="#{v}") }.join(" ")

      if id = options[:id]
        tag_attributes << %( id="#{id}")
      end

      html = ""
      html << %(<script src="#{script_url}" async defer></script>\n) if options.fetch(:script, true)
      html << %(<div class="g-recaptcha" #{tag_attributes}></div>\n)

      if options[:noscript] != false
        html << <<-HTML
          <noscript>
            <div>
              <div style="width: 302px; height: 422px; position: relative;">
                <div style="width: 302px; height: 422px; position: absolute;">
                  <iframe
                    src="#{fallback_uri}"
                    frameborder="0" scrolling="no"
                    style="width: 302px; height:422px; border-style: none;">
                  </iframe>
                </div>
              </div>
              <div style="width: 300px; height: 60px; border-style: none;
                bottom: 12px; left: 25px; margin: 0px; padding: 0px; right: 25px;
                background: #f9f9f9; border: 1px solid #c1c1c1; border-radius: 3px;">
                <textarea id="g-recaptcha-response" name="g-recaptcha-response"
                  class="g-recaptcha-response"
                  style="width: 250px; height: 40px; border: 1px solid #c1c1c1;
                  margin: 10px 25px; padding: 0px; resize: none;" value="">
                </textarea>
              </div>
            </div>
          </noscript>
        HTML
      end

      html.respond_to?(:html_safe) ? html.html_safe : html
    end
  end
end
