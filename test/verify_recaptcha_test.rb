require 'test/unit'
require 'rubygems'
require 'mocha'
require 'net/http'
require File.dirname(__FILE__) + '/../lib/recaptcha'

class VerifyReCaptchaTest < Test::Unit::TestCase
  class TestController < Struct.new(:request, :params, :session)
    include Ambethia::ReCaptcha
    include Ambethia::ReCaptcha::Helper
    include Ambethia::ReCaptcha::Controller
    
    attr_accessor :request, :params, :session
  end

  def setup
    @session = {}
    ENV['RECAPTCHA_PUBLIC_KEY']  = '0000000000000000000000000000000000000000'
    ENV['RECAPTCHA_PRIVATE_KEY'] = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
  end
  
  def test_invalid_private_key
    controller = TestController.new
    controller.request = stub(:remote_ip => "1.1.1.1")
    controller.params = {:recaptcha_challenge_field => "challenge", :recaptcha_response_field => "response"}
    controller.session = {}

    post_data = {}
    post_data[:privatekey] = ENV['RECAPTCHA_PRIVATE_KEY']
    post_data[:remoteip] = controller.request.remote_ip
    post_data[:challenge] = "challenge"
    post_data[:response] = "response"
    
    response = stub(:body => "false\ninvalid-site-private-key")
    Net::HTTP.expects(:post_form).with(expected_uri, post_data).returns(response)

    assert !controller.verify_recaptcha
    
    assert_equal "invalid-site-private-key", controller.session[:recaptcha_error]
  end
  
  def test_success
    controller = TestController.new
    controller.request = stub(:remote_ip => "1.1.1.1")
    controller.params = {:recaptcha_challenge_field => "challenge", :recaptcha_response_field => "response"}
    controller.session = {}

    post_data = {}
    post_data[:privatekey] = ENV['RECAPTCHA_PRIVATE_KEY']
    post_data[:remoteip] = controller.request.remote_ip
    post_data[:challenge] = "challenge"
    post_data[:response] = "response"
    
    response = stub(:body => "true\n")
    Net::HTTP.expects(:post_form).with(expected_uri, post_data).returns(response)

    assert controller.verify_recaptcha
    
    assert_nil controller.session[:recaptcha_error]
  end
  
  def expected_uri
    URI.parse("http://#{Ambethia::ReCaptcha::RECAPTCHA_VERIFY_SERVER}/verify")
  end    
end
