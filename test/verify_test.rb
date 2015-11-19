require_relative 'helper'

describe Recaptcha::Verify do
  before do
    @controller = TestController.new
    @controller.request = stub(:remote_ip => "1.1.1.1", format: :html)

    @expected_post_data = {}
    @expected_post_data["remoteip"]   = @controller.request.remote_ip
    @expected_post_data["response"]   = "response"

    # TODO test v1 ?
    # if Recaptcha.configuration.v1?
    #   @controller.params = {:recaptcha_challenge_field => "challenge", :recaptcha_response_field => "response"}
    #   @expected_post_data["privatekey"] = Recaptcha.configuration.private_key
    #   @expected_post_data["challenge"]  = "challenge"
    # end

    @controller.params = {:recaptcha_response_field => "response"}
    @expected_post_data["secret"] = Recaptcha.configuration.private_key

    @expected_uri = URI.parse(Recaptcha.configuration.verify_url)
  end

  describe "#verify_recaptcha!" do
    it "raises when it fails" do
      @controller.expects(:verify_recaptcha).returns(false)

      assert_raises Recaptcha::VerifyError do
        @controller.verify_recaptcha!
      end
    end

    it "returns a value when it passes" do
      @controller.expects(:verify_recaptcha).returns(:foo)

      assert_equal :foo, @controller.verify_recaptcha!
    end
  end

  describe "#verify_recaptcha" do
    it "returns true on success" do
      skip
      @controller.flash[:recaptcha_error] = "previous error that should be cleared"
      expect_http_post(response_with_body("true\n"))

      assert @controller.verify_recaptcha
      assert_nil @controller.flash[:recaptcha_error]
    end

    it "raises without private key" do
      skip "somehow this fails on travis :(" if ENV["CI"]
      Recaptcha.configuration.private_key = nil
      assert_raises Recaptcha::RecaptchaError do
        @controller.verify_recaptcha
      end
    end

    it "returns false when private key is invalid" do
      skip
      expect_http_post(response_with_body("false\ninvalid-site-private-key"))

      refute @controller.verify_recaptcha
      assert_equal "invalid-site-private-key", @controller.flash[:recaptcha_error]
    end

    it "adds an error to the model" do
      skip
      expect_http_post(response_with_body("false\nbad-news"))

      errors = mock
      errors.expects(:add).with(:base, "Word verification response is incorrect, please try again.")
      model = mock(:errors => errors)

      refute @controller.verify_recaptcha(:model => model)
      assert_equal "bad-news", @controller.flash[:recaptcha_error]
    end

    it "returns true on sccess with optional key" do
      skip
      @controller.flash[:recaptcha_error] = "previous error that should be cleared"
      # reset private key
      @expected_post_data["privatekey"] =  'ADIFFERENTPRIVATEKEYXXXXXXXXXXXXXX'
      expect_http_post(response_with_body("true\n"))

      assert @controller.verify_recaptcha(:private_key => 'ADIFFERENTPRIVATEKEYXXXXXXXXXXXXXX')
      assert_nil @controller.flash[:recaptcha_error]
    end

    it "fails silently when timing out" do
      skip
      expect_http_post(Timeout::Error, :exception => true)
      refute @controller.verify_recaptcha()
      assert_equal "Recaptcha unreachable.", @controller.flash[:recaptcha_error]
    end

    it "blows up on timeout when graceful is disabled" do
      skip
      Recaptcha.with_configuration(:handle_timeouts_gracefully => false) do
        expect_http_post(Timeout::Error, :exception => true)
        assert_raises Recaptcha::RecaptchaError, "Recaptcha unreachable." do
          assert @controller.verify_recaptcha()
        end
        assert_nil @controller.flash[:recaptcha_error]
      end
    end

    it "uses I18n for the message" do
      skip
      I18n.locale = :de
      verification_failed_translated   = "Sicherheitscode konnte nicht verifiziert werden."
      verification_failed_default      = "Word verification response is incorrect, please try again."
      recaptcha_unreachable_translated = "Netzwerkfehler, bitte versuchen Sie es später erneut."
      recaptcha_unreachable_default    = "Oops, we failed to validate your word verification response. Please try again."

      I18n.expects(:translate).with('recaptcha.errors.bad-news', {:default => 'bad-news'})
      I18n.expects(:translate).with('recaptcha.errors.recaptcha_unreachable', {:default => 'Recaptcha unreachable.'})

      I18n.expects(:translate).with('recaptcha.errors.verification_failed', :default => verification_failed_default).returns(verification_failed_translated)
      I18n.expects(:translate).with('recaptcha.errors.recaptcha_unreachable', :default => recaptcha_unreachable_default).returns(recaptcha_unreachable_translated)

      errors = mock
      errors.expects(:add).with(:base, verification_failed_translated)
      errors.expects(:add).with(:base, recaptcha_unreachable_translated)
      model  = mock; model.stubs(:errors => errors)

      expect_http_post(response_with_body("false\nbad-news"))
      @controller.verify_recaptcha(:model => model)

      expect_http_post(Timeout::Error, :exception => true)
      @controller.verify_recaptcha(:model => model)
    end

    it "translates api response with I18n" do
      skip
      api_error_translated = "Bad news, body :("
      expect_http_post(response_with_body("false\nbad-news"))
      I18n.expects(:translate).with('recaptcha.errors.bad-news', :default => 'bad-news').returns(api_error_translated)

      refute @controller.verify_recaptcha
      assert_equal api_error_translated, @controller.flash[:recaptcha_error]
    end

    it "falls back to api respnse if i18n translation is missing" do
      skip
      expect_http_post(response_with_body("false\nbad-news"))

      refute @controller.verify_recaptcha
      assert_equal 'bad-news', @controller.flash[:recaptcha_error]
    end

    it "does not flash error when request was not html" do
      skip
      @controller.request = stub(:remote_ip => "1.1.1.1", format: :json)
      expect_http_post(response_with_body("false\nbad-news"))
      refute @controller.verify_recaptcha
      assert_nil @controller.flash[:recaptcha_error]
    end
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
    if options[:exception]
      Net::HTTP.expects(:post_form).raises response
    else
      Net::HTTP.expects(:post_form).with(@expected_uri, @expected_post_data).returns(response)
    end
  end

  def response_with_body(body)
    stub(:body => body)
  end
end
