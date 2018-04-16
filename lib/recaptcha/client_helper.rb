# frozen_string_literal: true

require 'stringio'

module Recaptcha
  module ClientHelper
    # Your public API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def recaptcha_tags(options = {})
      if options.key?(:stoken)
        raise(RecaptchaError, 'Secure Token is deprecated. Please remove \'stoken\' from your calls to recaptcha_tags.')
      end
      if options.key?(:ssl)
        raise(RecaptchaError, 'SSL is now always true. Please remove \'ssl\' from your calls to recaptcha_tags.')
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
                    title="ReCAPTCHA"
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
      options = { callback: 'invisibleRecaptchaSubmit' }.merge options
      text = options.delete(:text)
      html, tag_attributes = Recaptcha::ClientHelper.recaptcha_components(options)
      html << recaptcha_default_callback if recaptcha_default_callback_required?(options)
      html << %(<button type="submit" #{tag_attributes}>#{text}</button>\n)
      html.respond_to?(:html_safe) ? html.html_safe : html
    end

    def self.recaptcha_components(options = {})
      html = StringIO.new
      attributes = {}
      fallback_uri = ''

      # Since leftover options get passed directly through as tag
      # attributes, we must unconditionally delete all our options
      options = options.dup
      env = options.delete(:env)
      class_attribute = options.delete(:class)
      site_key = options.delete(:site_key)
      hl = options.delete(:hl).to_s
      nonce = options.delete(:nonce)
      skip_script = options.delete(:script) == false
      data_attributes = {}
      %i[badge theme type callback expired_callback error_callback size tabindex].each do |data_attribute|
        value = options.delete(data_attribute)
        data_attributes["data-#{data_attribute.to_s.tr('_', '-')}"] = value if value
      end

      unless Recaptcha::Verify.skip?(env)
        site_key ||= Recaptcha.configuration.site_key!
        script_url =
          if hl == ''
            Recaptcha.configuration.api_server_url
          else
            "#{Recaptcha.configuration.api_server_url}?hl=#{hl}"
          end
        nonce_attr = " nonce='#{nonce}'" if nonce
        html << %(<script src="#{script_url}" async defer#{nonce_attr}></script>\n) unless skip_script
        fallback_uri = %(#{script_url.chomp('.js')}/fallback?k=#{site_key})
        attributes['data-sitekey'] = site_key
        attributes.merge! data_attributes
      end

      # Append whatever that's left of options to be attributes on the tag.
      attributes['class'] = "g-recaptcha #{class_attribute}"
      tag_attributes = attributes.merge(options).map { |k, v| %(#{k}="#{v}") }.join(' ')
      [html.string, tag_attributes, fallback_uri]
    end

    private

    def recaptcha_default_callback
      <<-HTML
        <script>
          var invisibleRecaptchaSubmit = function () {
            var closestForm = function (ele) {
              var curEle = ele.parentNode;
              while (curEle.nodeName !== 'FORM' && curEle.nodeName !== 'BODY'){
                curEle = curEle.parentNode;
              }
              return curEle.nodeName === 'FORM' ? curEle : null
            };

            var eles = document.getElementsByClassName('g-recaptcha');
            if (eles.length > 0) {
              var form = closestForm(eles[0]);
              if (form) {
                form.submit();
              }
            }
          };
        </script>
      HTML
    end

    def recaptcha_default_callback_required?(options)
      options[:callback] == 'invisibleRecaptchaSubmit' &&
        !Recaptcha::Verify.skip?(options[:env]) &&
        options[:script] != false
    end
  end
end
