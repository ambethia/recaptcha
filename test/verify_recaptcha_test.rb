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
  end

  def setup
    @session = {}
    ENV['RECAPTCHA_PUBLIC_KEY']  = '0000000000000000000000000000000000000000'
    ENV['RECAPTCHA_PRIVATE_KEY'] = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
  end
  
  def test_invalid_private_key
    request = stub(:remote_ip => "1.1.1.1")
    params = {:recaptcha_challenge_field => "", :recaptcha_response_field => ""}
    session = {}
    
    uri = URI.parse("http://#{Ambethia::ReCaptcha::RECAPTCHA_VERIFY_SERVER}/verify")
    post_data = {:privatekey => ENV['RECAPTCHA_PRIVATE_KEY'], :remoteip => request.remote_ip, :challenge => "", :response => ""}
    response = stub(:body => "false\ninvalid-site-private-key")
    Net::HTTP.expects(:post_form).with(uri, post_data).returns(response)

    controller = TestController.new(request, params, session)
    assert !controller.verify_recaptcha
    
    assert_equal "invalid-site-private-key", session[:recaptcha_error]
  end
end
