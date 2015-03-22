require 'minitest/autorun'
require 'cgi'
require File.dirname(File.expand_path(__FILE__)) + '/../lib/recaptcha'

class RecaptchaConfigurationTest < Minitest::Test
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
      config.api_version = 'v2'
    end
  end

  def test_recaptcha_api_version_default
    assert_equal(Recaptcha.configuration.api_version, Recaptcha::RECAPTCHA_API_VERSION)
  end

  def test_v2_with_v2_api?
    assert Recaptcha.configuration.v2?
    refute Recaptcha.configuration.v1?
  end

  def test_different_configuration_within_with_configuration_block
    key = Recaptcha.with_configuration(:public_key => '12345') do
      Recaptcha.configuration.public_key
    end

    assert_equal('12345', key)
  end

  def test_reset_configuration_after_with_configuration_block
    Recaptcha.with_configuration(:public_key => '12345')
    assert_equal('0000000000000000000000000000000000000000', Recaptcha.configuration.public_key)
  end
end