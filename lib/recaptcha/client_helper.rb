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

      noscript = options.delete(:noscript)

      html, tag_attributes, fallback_uri = Recaptcha::ClientHelper.recaptcha_components(options)
      html << %(<div #{tag_attributes}></div>\n)

      if noscript != false
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

    # Invisible reCAPTCHA implementation
    def invisible_recaptcha_tags(options = {})
      text = options.delete(:text)
      html, tag_attributes = Recaptcha::ClientHelper.recaptcha_components(options)

      html << %(<button type="submit" #{tag_attributes}>#{text}</button>\n)
      html.respond_to?(:html_safe) ? html.html_safe : html
    end

    def self.recaptcha_components(options = {})
      site_key = options.delete(:site_key) || Recaptcha.configuration.site_key!
      html = ""
      attributes = {
        class: ["g-recaptcha", options.delete(:class)].join(" ")
      }

      hl = options.delete(:hl)
      script_url = Recaptcha.configuration.api_server_url
      script_url += "?hl=#{hl}" unless hl.to_s == ""
      html << %(<script src="#{script_url}" async defer></script>\n) unless options.delete(:script) == false
      fallback_uri = "#{script_url.chomp('.js')}/fallback?k=#{site_key}"

      # Pull out reCaptcha specific data attributes.
      [:badge, :theme, :type, :callback, :expired_callback, :size].each do |data_attribute|
        if value = options.delete(data_attribute)
          attributes["data-#{data_attribute.to_s.tr('_', '-')}"] = value
        end
      end

      attributes["data-sitekey"] = site_key

      # Append whatever that's left of options to be attributes on the tag.
      tag_attributes = attributes.merge(options).map { |k, v| %(#{k}="#{v}") }.join(" ")

      [html, tag_attributes, fallback_uri]
    end
  end
end
