# frozen_string_literal: true

module Recaptcha
  module ClientHelper
    # Renders a reCAPTCHA [v2 Checkbox](https://developers.google.com/recaptcha/docs/display) widget
    def recaptcha_v2_checkbox(options = {})
      if options.key?(:stoken)
        raise(RecaptchaError, "Secure Token is deprecated. Please remove 'stoken' from your calls to recaptcha_tags.")
      end
      if options.key?(:ssl)
        raise(RecaptchaError, "SSL is now always true. Please remove 'ssl' from your calls to recaptcha_tags.")
      end

      options[:site_key] ||= Recaptcha.configuration.site_key_v2_checkbox!
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
                    name="ReCAPTCHA"
                    style="width: 302px; height: 422px; border-style: none; border: 0; overflow: hidden;">
                  </iframe>
                </div>
              </div>
              <div style="width: 300px; height: 60px; border-style: none;
                bottom: 12px; left: 25px; margin: 0px; padding: 0px; right: 25px;
                background: #f9f9f9; border: 1px solid #c1c1c1; border-radius: 3px;">
                <textarea id="g-recaptcha-response" name="g-recaptcha-response"
                  class="g-recaptcha-response"
                  style="width: 250px; height: 40px; border: 1px solid #c1c1c1;
                  margin: 10px 25px; padding: 0px; resize: none;">
                </textarea>
              </div>
            </div>
          </noscript>
        HTML
      end

      html.respond_to?(:html_safe) ? html.html_safe : html
    end
    alias_method :recaptcha_tags,    :recaptcha_v2_checkbox
    alias_method :recaptcha_v2_tags, :recaptcha_v2_checkbox

    # Renders a reCAPTCHA v2 [Invisible reCAPTCHA](https://developers.google.com/recaptcha/docs/invisible)
    def recaptcha_v2_invisible(options = {})
      options[:callback] ||= 'invisibleRecaptchaSubmit'
      options[:ui]       ||= :button
      options[:site_key] ||= Recaptcha.configuration.site_key_v2_invisible!
      text = options.delete(:text) || 'Submit'

      html, tag_attributes = Recaptcha::ClientHelper.recaptcha_components(options)
      html << recaptcha_default_callback(options) if recaptcha_default_callback_required?(options)
      case options[:ui]
      when :button
        html << %(<button type="submit" #{tag_attributes}>#{text}</button>\n)
      when :invisible
        html << %(<div data-size="invisible" #{tag_attributes}></div>\n)
      when :input
        html << %(<input type="submit" #{tag_attributes} value="#{text}"/>\n)
      else
        raise(RecaptchaError, "ReCAPTCHA ui `#{options[:ui]}` is not valid.")
      end
      html.respond_to?(:html_safe) ? html.html_safe : html
    end
    alias_method :invisible_recaptcha_tags, :recaptcha_v2_invisible

    # Renders a [reCAPTCHA v3](https://developers.google.com/recaptcha/docs/v3) script and (by
    # default) a hidden input to submit the response token.
    def recaptcha_v3(options = {})
      action = options.delete(:action) || raise(Recaptcha::RecaptchaError, 'action is required')
      site_key = options[:site_key] ||= Recaptcha.configuration.site_key_v3!
      id   = options.delete(:id)   || "g-recaptcha-response-" + dasherize_action(action)
      name = options.delete(:name) || "g-recaptcha-response[#{action}]"
      options[:render] = site_key
      options[:script_async] ||= false
      options[:script_defer] ||= false
      element = options.delete(:element)
      element = element == false ? false : :input
      if element == :input
        callback = options.delete(:callback) || recaptcha_v3_default_callback_name(action)
      end
      options[:class] = "g-recaptcha-response #{options[:class]}"

      html, tag_attributes = Recaptcha::ClientHelper.recaptcha_components(options)
      if recaptcha_v3_inline_script?(options)
        html << recaptcha_v3_inline_script(site_key, action, callback, id, options)
      end
      case element
      when :input
        html << %(<input type="hidden" name="#{name}" id="#{id}" #{tag_attributes}/>\n)
      when false
        # No tag
        nil
      else
        raise(RecaptchaError, "ReCAPTCHA element `#{options[:element]}` is not valid.")
      end
      html.respond_to?(:html_safe) ? html.html_safe : html
    end
    alias_method :recaptcha_v3_tags, :recaptcha_v3

    # @private
    def self.recaptcha_components(options = {})
      html = +''
      attributes = {}
      fallback_uri = +''

      # Since leftover options get passed directly through as tag
      # attributes, we must unconditionally delete all our options
      options = options.dup
      env = options.delete(:env)
      class_attribute = options.delete(:class)
      site_key = options.delete(:site_key)
      hl = options.delete(:hl)
      onload = options.delete(:onload)
      render = options.delete(:render)
      script_async = options.delete(:script_async)
      script_defer = options.delete(:script_defer)
      nonce = options.delete(:nonce)
      skip_script = (options.delete(:script) == false) || (options.delete(:external_script) == false)
      ui = options.delete(:ui)

      data_attribute_keys = [:badge, :theme, :type, :callback, :expired_callback, :error_callback, :size]
      data_attribute_keys << :tabindex unless ui == :button
      data_attributes = {}
      data_attribute_keys.each do |data_attribute|
        value = options.delete(data_attribute)
        data_attributes["data-#{data_attribute.to_s.tr('_', '-')}"] = value if value
      end

      unless Recaptcha::Verify.skip?(env)
        site_key ||= Recaptcha.configuration.site_key!
        script_url = Recaptcha.configuration.api_server_url
        query_params = hash_to_query(
          hl: hl,
          onload: onload,
          render: render
        )
        script_url += "?#{query_params}" unless query_params.empty?
        async_attr = "async" if script_async != false
        defer_attr = "defer" if script_defer != false
        nonce_attr = " nonce='#{nonce}'" if nonce
        html << %(<script src="#{script_url}" #{async_attr} #{defer_attr} #{nonce_attr}></script>\n) unless skip_script
        fallback_uri = %(#{script_url.chomp(".js")}/fallback?k=#{site_key})
        attributes["data-sitekey"] = site_key
        attributes.merge! data_attributes
      end

      # The remaining options will be added as attributes on the tag.
      attributes["class"] = "g-recaptcha #{class_attribute}"
      tag_attributes = attributes.merge(options).map { |k, v| %(#{k}="#{v}") }.join(" ")

      [html, tag_attributes, fallback_uri]
    end

    private

    # Default callback used by invisible_recaptcha_tags
    # Can be skipped by passing script: false, inline_script: false, or a value for callback other
    # than 'invisibleRecaptchaSubmit'.
    def recaptcha_default_callback(options = {})
      nonce = options[:nonce]
      nonce_attr = " nonce='#{nonce}'" if nonce

      <<-HTML
        <script#{nonce_attr}>
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
      (options[:script] != false) &&
      (options[:inline_script] != false)
    end

    # Renders a script that calls `grecaptcha.execute` for the given `site_key` and `action` and
    # calls the `callback` with the resulting response token.
    def recaptcha_v3_inline_script(site_key, action, callback, id, options = {})
      nonce = options[:nonce]
      nonce_attr = " nonce='#{nonce}'" if nonce

      <<-HTML
        <script#{nonce_attr}>
          // Define function so that we can call it again later if we need to reset it
          var #{recaptcha_v3_execute_function_name(action)} = function() {
            grecaptcha.ready(function() {
              grecaptcha.execute('#{site_key}', {action: '#{action}'}).then(function(token) {
                console.log('#{id}', token)
                #{callback}('#{id}', token)
              });
            });
          };
          // Invoke immediately
          #{recaptcha_v3_execute_function_name(action)}()

          #{recaptcha_v3_define_default_callback(callback) if recaptcha_v3_define_default_callback?(callback, action, options)}
        </script>
      HTML
    end

    def recaptcha_v3_inline_script?(options)
      !Recaptcha::Verify.skip?(options[:env]) &&
      (options[:script] != false) &&
      (options[:inline_script] != false)
    end

    def recaptcha_v3_define_default_callback(callback)
      <<-HTML
          var #{callback} = function(id, token) {
            var element = document.getElementById(id);
            element.value = token;
          }
        </script>
      HTML
    end

    # Returns true if we should be adding the default callback.
    # That is, if the given callback name is the default callback name (for the given action) and we
    # are not skipping inline scripts for any reason.
    def recaptcha_v3_define_default_callback?(callback, action, options)
      callback == recaptcha_v3_default_callback_name(action) &&
      !Recaptcha::Verify.skip?(options[:env]) &&
      (options[:script] != false) &&
      (options[:inline_script] != false)
    end

    def recaptcha_v3_execute_function_name(action)
      "executeRecaptchaFor#{sanitize_action_for_js(action)}"
    end

    def recaptcha_v3_default_callback_name(action)
      "setInputWithRecaptchaResponseTokenFor#{sanitize_action_for_js(action)}"
    end

    # Returns a camelized string that is safe for use in a JavaScript variable/function name.
    # sanitize_action_for_js('my/action') => 'MyAction'
    def sanitize_action_for_js(action)
      action.to_s.gsub(/\W/, '_').camelize
    end

    # Returns a dasherized string that is safe for use as an HTML ID
    # dasherize_action('my/action') => 'my-action'
    def dasherize_action(action)
      action.to_s.gsub(/\W/, '-').dasherize
    end

    private_class_method def self.hash_to_query(hash)
      hash.delete_if { |_, val| val.nil? || val.empty? }.to_a.map { |pair| pair.join('=') }.join('&')
    end
  end
end
