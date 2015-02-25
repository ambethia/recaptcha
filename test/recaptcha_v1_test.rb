require 'minitest/autorun'
require 'cgi'
require File.dirname(File.expand_path(__FILE__)) + '/../lib/recaptcha'

class RecaptchaV1Test < Minitest::Test
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
      config.api_version = 'v1'
    end
  end

  def test_v1_with_v1_api?
    assert Recaptcha.configuration.v1?
    refute Recaptcha.configuration.v2?
  end

  def test_recaptcah_tags_v1
    Recaptcha.configuration.api_version = 'v1'
    # match a v1 only tag
    assert_match /\/challenge\?/, recaptcha_tags
    # refute a v2 only tag
    refute_match /data-sitekey/, recaptcha_tags
  end
end