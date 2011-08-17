# coding: utf-8

require 'test/unit'
require 'rubygems'
require 'active_support/core_ext/string'
require 'mocha'
require 'i18n'
require 'net/http'
require File.dirname(File.expand_path(__FILE__)) + '/../lib/recaptcha'

class RecaptchaVerifyTest < Test::Unit::TestCase
  def setup
    Recaptcha.configuration.private_key = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    @controller = TestController.new
    @controller.request = stub(:remote_ip => "1.1.1.1")
    @controller.params = {:recaptcha_challenge_field => "challenge", :recaptcha_response_field => "response"}

    @expected_post_data = {}
    @expected_post_data["privatekey"] = Recaptcha.configuration.private_key
    @expected_post_data["remoteip"]   = @controller.request.remote_ip
    @expected_post_data["challenge"]  = "challenge"
    @expected_post_data["response"]   = "response"

    @expected_uri = URI.parse(Recaptcha.configuration.verify_url)
  end

  def test_should_raise_exception_without_private_key
    assert_raise Recaptcha::RecaptchaError do
      Recaptcha.configuration.private_key = nil
      @controller.verify_recaptcha
    end
  end

  def test_should_return_false_when_key_is_invalid
    expect_http_post(response_with_body("false\ninvalid-site-private-key"))

    assert !@controller.verify_recaptcha
    assert_equal "invalid-site-private-key", @controller.flash[:recaptcha_error]
  end

  def test_returns_true_on_success
    @controller.flash[:recaptcha_error] = "previous error that should be cleared"
    expect_http_post(response_with_body("true\n"))

    assert @controller.verify_recaptcha
    assert_nil @controller.flash[:recaptcha_error]
  end

  def test_errors_should_be_added_to_model
    expect_http_post(response_with_body("false\nbad-news"))

    errors = mock
    errors.expects(:add).with(:base, "Word verification response is incorrect, please try again.")
    model = mock(:errors => errors)

    assert !@controller.verify_recaptcha(:model => model)
    assert_equal "bad-news", @controller.flash[:recaptcha_error]
  end

  def test_returns_true_on_success_with_optional_key
    @controller.flash[:recaptcha_error] = "previous error that should be cleared"
    # reset private key
    @expected_post_data["privatekey"] =  'ADIFFERENTPRIVATEKEYXXXXXXXXXXXXXX'
    expect_http_post(response_with_body("true\n"))

    assert @controller.verify_recaptcha(:private_key => 'ADIFFERENTPRIVATEKEYXXXXXXXXXXXXXX')
    assert_nil @controller.flash[:recaptcha_error]
  end

  def test_timeout
    expect_http_post(Timeout::Error, :exception => true)
    assert !@controller.verify_recaptcha()
    assert_equal "recaptcha-not-reachable", @controller.flash[:recaptcha_error]
  end

  def test_message_should_use_i18n
    I18n.locale = :de
    verification_failed_translated   = "Sicherheitscode konnte nicht verifiziert werden."
    verification_failed_default      = "Word verification response is incorrect, please try again."
    recaptcha_unreachable_translated = "Netzwerkfehler, bitte versuchen Sie es später erneut."
    recaptcha_unreachable_default    = "Oops, we failed to validate your word verification response. Please try again."
    I18n.expects(:translate).with(:'recaptcha.errors.verification_failed', :default => verification_failed_default).returns(verification_failed_translated)
    I18n.expects(:translate).with(:'recaptcha.errors.recaptcha_unreachable', :default => recaptcha_unreachable_default).returns(recaptcha_unreachable_translated)

    errors = mock
    errors.expects(:add).with(:base, verification_failed_translated)
    errors.expects(:add).with(:base, recaptcha_unreachable_translated)
    model  = mock; model.stubs(:errors => errors)

    expect_http_post(response_with_body("false\nbad-news"))
    @controller.verify_recaptcha(:model => model)

    expect_http_post(Timeout::Error, :exception => true)
    @controller.verify_recaptcha(:model => model)

  end

  private

  class TestController
    include Recaptcha::Verify
    attr_accessor :request, :params, :flash

    def initialize
      @flash = {}
    end
  end

  def expect_http_post(response, options = {})
    unless options[:exception]
      Net::HTTP.expects(:post_form).with(@expected_uri, @expected_post_data).returns(response)
    else
      Net::HTTP.expects(:post_form).raises response
    end
  end

  def response_with_body(body)
    stub(:body => body)
  end
end
