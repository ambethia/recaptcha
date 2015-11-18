require_relative 'helper'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash'

describe Recaptcha::ClientHelper do
  include Recaptcha::ClientHelper

  describe "v1" do
    before do
      Recaptcha.configuration.api_version = 'v1'
    end

    it "uses v1 tags" do
      assert_match /\/challenge\?/, recaptcha_tags
    end

    it "does not use v2 tags" do
      refute_match /data-sitekey/, recaptcha_tags
    end
  end

  describe "v2" do
    it "uses v2 tags" do
      assert_match /data-sitekey/, recaptcha_tags
    end

    it "does not use v1 tags" do
      refute_match /\/challenge\?/, recaptcha_tags
    end
  end

  describe "ssl" do
    before do
      @nonssl_api_server_url = Regexp.new(Regexp.quote(Recaptcha.configuration.nonssl_api_server_url) + '(.*)')
      @ssl_api_server_url = Regexp.new(Regexp.quote(Recaptcha.configuration.ssl_api_server_url) + '(.*)')
    end

    it "uses ssl when ssl by default is on" do
      Recaptcha.configuration.use_ssl_by_default = true
      assert_match @ssl_api_server_url, recaptcha_tags
    end

    it "does not use ssl when ssl by default is off" do
      assert_match @nonssl_api_server_url, recaptcha_tags
    end

    it "does not use ssl when ssl by default is overwritten" do
      Recaptcha.configuration.use_ssl_by_default = true
      assert_match @nonssl_api_server_url, recaptcha_tags(ssl: false)
    end

    it "uses ssl when ssl by default is overwritten to true" do
      assert_match @nonssl_api_server_url, recaptcha_tags(ssl: true)
    end
  end

  describe "noscript" do
    it "does not adds noscript tags when noscript is given" do
      recaptcha_tags(noscript: false).wont_include "noscript"
    end

    it "does not add noscript tags" do
      recaptcha_tags.must_include "noscript"
    end
  end

  describe "stoken" do
    let(:regex) { /" data-stoken="[1]" / }

    it "adds a security token by default" do
      html = recaptcha_tags
      html.sub!(/data-stoken="[^"]+"/, 'data-stoken="TOKEN"')
      html.must_include "<div class=\"g-recaptcha\" data-sitekey=\"0000000000000000000000000000000000000000\" data-stoken=\"TOKEN\"></div>"
    end

    it "does not add a security token when specified" do
      html = recaptcha_tags(stoken: false)
      html.must_include "<div class=\"g-recaptcha\" data-sitekey=\"0000000000000000000000000000000000000000\"></div>"
    end
  end

  it "raises withut public key" do
    Recaptcha.configuration.public_key = nil
    assert_raises Recaptcha::RecaptchaError do
      recaptcha_tags
    end
  end
end
