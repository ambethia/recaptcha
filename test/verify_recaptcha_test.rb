require 'test/unit'
require 'rubygems'
require 'mocha'
require 'net/http'
require File.dirname(__FILE__) + '/../lib/recaptcha'

class VerifyReCaptchaTest < Test::Unit::TestCase
  def setup
    ENV['RECAPTCHA_PRIVATE_KEY'] = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

    @controller = TestController.new
    @controller.request = stub(:remote_ip => "1.1.1.1")
    @controller.params = {:recaptcha_challenge_field => "challenge", :recaptcha_response_field => "response"}

    @expected_post_data = {}
    @expected_post_data[:privatekey] = ENV['RECAPTCHA_PRIVATE_KEY']
    @expected_post_data[:remoteip] = @controller.request.remote_ip
    @expected_post_data[:challenge] = "challenge"
    @expected_post_data[:response] = "response"
    
    @expected_uri = URI.parse("http://#{Ambethia::ReCaptcha::RECAPTCHA_VERIFY_SERVER}/verify")
  end
  
  def test_should_raise_exception_without_private_key
    assert_raise Ambethia::ReCaptcha::ReCaptchaError do
      ENV['RECAPTCHA_PRIVATE_KEY'] = nil
      @controller.verify_recaptcha
    end
  end

  def test_should_return_false_when_key_is_invalid
    expect_http_post(response_with_body("false\ninvalid-site-private-key"))

    assert !@controller.verify_recaptcha    
    assert_equal "invalid-site-private-key", @controller.session[:recaptcha_error]
  end
  
  def test_returns_true_on_success
    @controller.session[:recaptcha_error] = "previous error that should be cleared"    
    expect_http_post(response_with_body("true\n"))

    assert @controller.verify_recaptcha
    assert_nil @controller.session[:recaptcha_error]
  end
  
  def test_errors_should_be_added_to_model
    expect_http_post(response_with_body("false\nbad-news"))
    
    errors = mock
    errors.expects(:add_to_base).with("Captcha response is incorrect, please try again.")
    
    model = mock
    model.expects(:valid?)
    model.expects(:errors).returns(errors)

    assert !@controller.verify_recaptcha(:model => model)
    assert_equal "bad-news", @controller.session[:recaptcha_error]
  end

  def test_returns_true_on_success_with_optional_key
    @controller.session[:recaptcha_error] = "previous error that should be cleared"
    # reset private key
    @expected_post_data[:privatekey] =  'ADIFFERENTPRIVATEKEYXXXXXXXXXXXXXX'
    expect_http_post(response_with_body("true\n"))

    assert @controller.verify_recaptcha(:private_key => 'ADIFFERENTPRIVATEKEYXXXXXXXXXXXXXX')
    assert_nil @controller.session[:recaptcha_error]
  end
  
  private
  
  class TestController
    include Ambethia::ReCaptcha::Controller    
    attr_accessor :request, :params, :session
    
    def initialize
      @session = {}
    end
  end
  
  def expect_http_post(response)
    Net::HTTP.expects(:post_form).with(@expected_uri, @expected_post_data).returns(response)
  end
  
  def response_with_body(body)
    stub(:body => body)
  end
end
