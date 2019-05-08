# frozen_string_literal: true

module Recaptcha
  module ClientHelper
    def self.components(options = {})
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
      nonce = options.delete(:nonce)
      skip_script = (options.delete(:script) == false)
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
        nonce_attr = " nonce='#{nonce}'" if nonce
        html << %(<script src="#{script_url}" async defer#{nonce_attr}></script>\n) unless skip_script
        fallback_uri = %(#{script_url.chomp(".js")}/fallback?k=#{site_key})
        attributes["data-sitekey"] = site_key
        attributes.merge! data_attributes
      end

      # Append whatever that's left of options to be attributes on the tag.
      attributes["class"] = "g-recaptcha #{class_attribute}"
      tag_attributes = attributes.merge(options).map { |k, v| %(#{k}="#{v}") }.join(" ")

      [html, tag_attributes, fallback_uri]
    end

    def self.default_callback(options = {})
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

    def self.default_callback_required?(options)
      options[:callback] == 'invisibleRecaptchaSubmit' &&
      !Recaptcha::Verify.skip?(options[:env]) &&
      options[:script] != false
    end

    def self.hash_to_query(hash)
      hash.delete_if { |_, val| val.nil? || val.empty? }.to_a.map { |pair| pair.join('=') }.join('&')
    end
  end
end
