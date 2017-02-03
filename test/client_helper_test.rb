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

  it "does not include <script> tag when setting script: false" do
    html = recaptcha_tags(script: false)
    html.wont_include("<script")
  end

  describe "invisible recatpcha" do
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
  end
end
