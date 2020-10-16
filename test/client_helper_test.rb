require_relative 'helper'

describe 'View helpers' do
  include Recaptcha::Adapters::ViewMethods

  it "uses ssl" do
    recaptcha_tags.must_include "\"#{Recaptcha.configuration.api_server_url}\""
  end

  describe "noscript" do
    it "does not add noscript tags when noscript is given" do
      recaptcha_tags(noscript: false).wont_include "noscript"
    end

    it "does not add noscript tags" do
      recaptcha_tags.must_include "noscript"
    end
  end

  it "can include size" do
    html = recaptcha_tags(size: 10)
    html.must_include("data-size=\"10\"")
  end

  it "raises without site key" do
    Recaptcha.configuration.site_key = nil
    assert_raises Recaptcha::RecaptchaError do
      recaptcha_tags
    end
  end

  it "includes id as div attribute" do
    html = recaptcha_tags(id: 'my_id')
    html.must_include(" id=\"my_id\"")
  end

  it "translates tabindex attribute to data- attribute for recaptcha_tags" do
    html = recaptcha_tags(tabindex: 123)
    html.must_include(" data-tabindex=\"123\"")
  end

  it "leaves tabindex attribute as-is for invisible_recaptcha_tags" do
    html = invisible_recaptcha_tags(tabindex: 123)
    html.must_include(" tabindex=\"123\"")
  end

  it "includes nonce attribute" do
    html = recaptcha_tags(nonce: 'P9Y0b6dLSkApYRdOULGW57XHcYNJJKeLwxA2az/Ka9s=')
    html.must_include(" nonce='P9Y0b6dLSkApYRdOULGW57XHcYNJJKeLwxA2az/Ka9s='")
  end

  it "does not include <script> tag when setting script: false" do
    html = recaptcha_tags(script: false)
    html.wont_include("<script")
  end

  it "adds :hl option to the url" do
    html = recaptcha_tags(hl: 'en')
    html.must_include("hl=en")

    html = recaptcha_tags(hl: 'ru')
    html.wont_include("hl=en")
    html.must_include("hl=ru")

    html = recaptcha_tags
    html.wont_include("hl=")
  end

  it "adds :onload option to the url" do
    html = recaptcha_tags(onload: 'foobar')
    html.must_include("onload=foobar")

    html = recaptcha_tags(onload: 'anotherFoobar')
    html.wont_include("onload=foobar")
    html.must_include("onload=anotherFoobar")

    html = recaptcha_tags
    html.wont_include("onload=")
  end

  describe "turbolinks" do
    it "adds onload to defined function" do
      html = recaptcha_v3(action: 'request', turbolinks: true)
      html.must_include("onload=executeRecaptchaForRequest")
    end

    it "overrides specified onload" do
      html = recaptcha_v3(action: 'request', onload: "foobar", turbolinks: true)
      html.wont_include("onload=foobar")
      html.must_include("onload=executeRecaptchaForRequest")
    end
  end

  it "adds :render option to the url" do
    html = recaptcha_tags(render: 'onload')
    html.must_include("render=onload")

    html = recaptcha_tags(render: 'explicit')
    html.wont_include("render=onload")
    html.must_include("render=explicit")

    html = recaptcha_tags
    html.wont_include("render=")
  end

  it "adds query params to the url" do
    html = recaptcha_tags(hl: 'en', onload: 'foobar')
    html.must_include("?")
    html.must_include("hl=en")
    html.must_include("&")
    html.must_include("onload=foobar")
  end

  it "includes the site key in the button attributes" do
    html = invisible_recaptcha_tags
    html.must_include(" data-sitekey=\"#{Recaptcha.configuration.site_key}\"")
  end

  it "lets you override the site_key from configuration via options hash" do
    html = invisible_recaptcha_tags(site_key: 'different_key')
    html.must_include(" data-sitekey=\"different_key\"")
  end

  it "dasherizes the expired_callback attribute name" do
    html = recaptcha_tags(expired_callback: 'my_expired_callback')
    html.must_include(" data-expired-callback=\"my_expired_callback\"")
  end

  it "dasherizes error_callback attribute name" do
    html = recaptcha_tags(error_callback: 'my_error_callback')
    html.must_include(" data-error-callback=\"my_error_callback\"")
  end

  describe "invisible recaptcha" do
    it "uses ssl" do
      invisible_recaptcha_tags.must_include "\"#{Recaptcha.configuration.api_server_url}\""
    end

    it "raises without site key" do
      Recaptcha.configuration.site_key = nil
      assert_raises Recaptcha::RecaptchaError do
        invisible_recaptcha_tags
      end
    end

    it "includes id as button attribute" do
      html = invisible_recaptcha_tags(id: 'my_id')
      html.must_include(" id=\"my_id\"")
    end

    it "does not include <script> tag when setting script: false" do
      html = invisible_recaptcha_tags(script: false)
      html.wont_include("<script")
    end

    it "renders other attributes" do
      html = invisible_recaptcha_tags(foo_attr: 'foo_value')
      html.must_include(" foo_attr=\"foo_value\"")
    end

    it "renders other attributes when verification is disabled" do
      html = invisible_recaptcha_tags(env: "test", foo_attr: 'foo_value')
      html.must_include(" foo_attr=\"foo_value\"")
    end

    it "includes the site key in the button attributes" do
      html = invisible_recaptcha_tags
      html.must_include(" data-sitekey=\"#{Recaptcha.configuration.site_key}\"")
    end

    it "doesn't render script tag when verification is disabled" do
      html = invisible_recaptcha_tags(env: "test")
      html.wont_include("<script")
      html.wont_include("data-sitekey=")
    end

    it "doesn't include recaptcha attributes when verification is disabled" do
      html = invisible_recaptcha_tags(env: "test")
      [:badge, :theme, :callback, :expired_callback, :error_callback, :size, :tabindex].each do |data_attribute|
        html.wont_include("#{data_attribute}=")
      end
    end

    it "renders default callback if no callback is given" do
      html = invisible_recaptcha_tags
      html.must_include("var invisibleRecaptchaSubmit")
    end

    it "doesn't render default callback script if a callback is given" do
      html = invisible_recaptcha_tags(callback: 'customCallback')
      html.wont_include("var invisibleRecaptchaSubmit")
    end

    it "includes a nonce if provided" do
      html = invisible_recaptcha_tags(nonce: "dummyNonce")
      html.must_include("<script nonce='dummyNonce'>")
    end

    it "renders a div if UI is invisible" do
      html = invisible_recaptcha_tags(ui: :invisible)
      html.must_include("<div data-size=\"invisible\"")
      html.wont_include("<button")
    end

    it "renders an input element with supplied text if UI is input" do
      html = invisible_recaptcha_tags(ui: :input, text: 'Send')
      html.must_include("<input type=\"submit\"")
      html.must_include("value=\"Send\"/>")
      html.wont_include("<button")
    end

    it "includes a custom selector if provided" do
      html = invisible_recaptcha_tags(id: 'custom-selector')
      html.must_include("id=\"custom-selector\"")
      html.must_include("document.querySelector(\"#custom-selector\")")
    end

    it "uses default selector if no custom selector has been provided" do
      html = invisible_recaptcha_tags
      html.must_include("document.querySelector(\".g-recaptcha\")")
    end

    it "raises an error on an invalid ui option" do
      assert_raises Recaptcha::RecaptchaError do
        invisible_recaptcha_tags(ui: :foo)
      end
    end
  end

  describe "v3 recaptcha" do
    it "renders input" do
      html = recaptcha_v3 action: :foo
      html.must_include('<input type="hidden" name="g-recaptcha-response-data[foo]" id="g-recaptcha-response-data-foo" data-sitekey="0000000000000000000000000000000000000000" class="g-recaptcha g-recaptcha-response "/>')
    end

    it "does not have obsole closing script tag" do
      html = recaptcha_v3 action: :foo
      assert html.scan(/script/).length.even?
    end
  end
end
