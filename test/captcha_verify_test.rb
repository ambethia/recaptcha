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

    @expected_uri = Recaptcha.configuration.verify_url
  end
  
  
  def test_should_raise_exception_without_private_key_captcha_verify
    assert_raise Recaptcha::RecaptchaError do
      Recaptcha.configuration.private_key = nil
      @controller.captcha_verify
    end
  end

  def test_returns_true_if_params_has_not_recaptcha_fields
    @controller.params = {}
    assert_equal @controller.captcha_verify, true
  end

  def test_raise_error_when_response_returned_false
    expect_http_post("false\nbad")

    assert_raise Recaptcha::RecaptchaVerifyError do
      @controller.captcha_verify
    end
    assert_equal "bad", @controller.flash[:recaptcha_error]
  end

  def test_returned_false_when_response_returned_true 
    expect_http_post("true\nbad")
    assert_equal false, @controller.captcha_verify
  end
  
  def test_timeout_error
    expect_http_post(Timeout::Error, :exception => true)
    assert_raise Recaptcha::RecaptchaVerifyError do
      @controller.captcha_verify
    end
    assert_equal 'Recaptcha unreachable.', @controller.flash[:recaptcha_error]
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
      stub_request(:post, @expected_uri).with(@expected_post_data).to_return(:body => response)
    else
      stub_request(:post, @expected_uri).to_raise(response) 
    end 
  end

  def response_with_body(body)
    body
  end
  
end

