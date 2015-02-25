require 'minitest/autorun'
require 'cgi'
require File.dirname(File.expand_path(__FILE__)) + '/../lib/recaptcha'

class RecaptchaClientHelperTest < Minitest::Test
  include Recaptcha
  include Recaptcha::ClientHelper
  include Recaptcha::Verify

  attr_accessor :session

  def setup
    @session = {}
    @nonssl_api_server_url = Regexp.new(Regexp.quote(Recaptcha.configuration.nonssl_api_server_url) + '(.*)')
    @ssl_api_server_url = Regexp.new(Regexp.quote(Recaptcha.configuration.ssl_api_server_url) + '(.*)')
    Recaptcha.configure do |config|
      config.public_key = '0000000000000000000000000000000000000000'
      config.private_key = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    end
  end

  def test_recaptcha_tags_v2
    Recaptcha.configuration.api_version = 'v2'
    # match a v2 only tag
    assert_match /data-sitekey/, recaptcha_tags
    # refute a v1 only tag
    refute_match /\/challenge\?/, recaptcha_tags
  end

  def test_ssl_by_default
    Recaptcha.configuration.use_ssl_by_default = true
    assert_match @ssl_api_server_url, recaptcha_tags
  end

  def test_relative_protocol_by_default_without_ssl
    Recaptcha.configuration.use_ssl_by_default = false
    assert_match @nonssl_api_server_url, recaptcha_tags(:ssl => false)
  end

  def test_recaptcha_tags_with_ssl
    assert_match @ssl_api_server_url, recaptcha_tags(:ssl => true)
  end

  def test_recaptcha_tags_without_noscript
    refute_match /noscript/, recaptcha_tags(:noscript => false)
  end

  def test_should_raise_exception_without_public_key
    assert_raises RecaptchaError do
      Recaptcha.configuration.public_key = nil
      recaptcha_tags
    end
  end
end
