require_relative 'helper'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash'

describe Recaptcha::ClientHelper do
  include Recaptcha::ClientHelper

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

  it "includes tabindex attribute" do
    html = recaptcha_tags(tabindex: 123)
    html.must_include(" data-tabindex=\"123\"")
  end

  it "does not include <script> tag when setting script: false" do
    html = recaptcha_tags(script: false)
    html.wont_include("<script")
  end

  it "adds :hl option to the url" do
    html = recaptcha_tags(hl: 'en')
    html.must_include("?hl=en")

    html = recaptcha_tags(hl: 'ru')
    html.wont_include("?hl=en")
    html.must_include("?hl=ru")

    html = recaptcha_tags
    html.wont_include("?hl=")
  end

  it "includes the site key in the button attributes" do
    html = invisible_recaptcha_tags
    html.must_include(" data-sitekey=\"#{Recaptcha.configuration.site_key}\"")
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

    it "includes the site key in the button attributes" do
      html = invisible_recaptcha_tags
      html.must_include(" data-sitekey=\"#{Recaptcha.configuration.site_key}\"")
    end

    it "doesn't render script tag when verification is disabled" do
      html = invisible_recaptcha_tags(env: "test")
      html.wont_include("<script")
      html.wont_include("data-sitekey=")
    end

    it "renders default callback if no callback is given" do
      html = invisible_recaptcha_tags
      html.must_include("var invisibleRecaptchaSubmit")
    end

    it "doesn't render default callback script if a callback is given" do
      html = invisible_recaptcha_tags(callback: 'customCallback')
      html.wont_include("var invisibleRecaptchaSubmit")
    end
  end
end
