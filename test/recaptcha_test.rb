require 'test/unit'
require 'cgi'
require File.dirname(File.expand_path(__FILE__)) + '/../lib/recaptcha'

class RecaptchaClientHelperTest < Test::Unit::TestCase
  include Recaptcha
  include Recaptcha::ClientHelper
  include Recaptcha::Verify

  attr_accessor :session

  def setup
    @session = {}
    Recaptcha.configure do |config|
      config.public_key = '0000000000000000000000000000000000000000'
      config.private_key = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    end
  end

  def test_recaptcha_tags
    # Might as well match something...
    assert_match /http:\/\/www.google.com\/recaptcha\/api\/challenge/, recaptcha_tags
  end

  def test_recaptcha_tags_with_ssl
    assert_match /https:\/\/www.google.com\/recaptcha\/api\/challenge/, recaptcha_tags(:ssl => true)
  end

  def test_recaptcha_tags_without_noscript
    assert_no_match /noscript/, recaptcha_tags(:noscript => false)
  end

  def test_should_raise_exception_without_public_key
    assert_raise RecaptchaError do
      Recaptcha.configuration.public_key = nil
      recaptcha_tags
    end
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
