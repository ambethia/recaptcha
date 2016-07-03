require_relative 'helper'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash'

describe Recaptcha::ClientHelper do
  include Recaptcha::ClientHelper

  it "uses ssl" do
    recaptcha_tags.must_include "\"#{Recaptcha.configuration.api_server_url}\""
  end

  describe "noscript" do
    it "does not adds noscript tags when noscript is given" do
      recaptcha_tags(noscript: false).wont_include "noscript"
    end

    it "does not add noscript tags" do
      recaptcha_tags.must_include "noscript"
    end
  end

  it "can include size" do
    html = recaptcha_tags(size: 10)
    html.must_include(
      "<div class=\"g-recaptcha\" data-size=\"10\" data-sitekey=\"0000000000000000000000000000000000000000\""
    )
  end

  it "raises withut public key" do
    Recaptcha.configuration.public_key = nil
    assert_raises Recaptcha::RecaptchaError do
      recaptcha_tags
    end
  end

  it "should include id to div attribute" do
    html = recaptcha_tags(id: 'my_id')
    html.must_include(
      " id=\"my_id\""
    )
  end

  it "shouldn't include <script> tag" do
    html = recaptcha_tags(script: false)
    html.wont_include(
      "<script"
    )
  end
end
