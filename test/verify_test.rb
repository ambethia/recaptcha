require_relative 'helper'

describe 'controller helpers' do
  before do
    @controller = TestController.new
    @controller.request = stub(remote_ip: "1.1.1.1", format: :html)

    @expected_post_data = {}
    @expected_post_data["remoteip"]   = @controller.request.remote_ip
    @expected_post_data["response"]   = "response"

    @controller.params = {:recaptcha_response_field => "response", 'g-recaptcha-response-data' => 'string'}
    @expected_post_data["secret"] = Recaptcha.configuration.secret_key

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
      @controller.flash[:recaptcha_error] = "previous error that should be cleared"
      expect_http_post.to_return(body: '{"success":true}')

      assert @controller.verify_recaptcha
      assert_nil @controller.flash[:recaptcha_error]
    end

    it "raises without secret key" do
      Recaptcha.configuration.secret_key = nil
      assert_raises Recaptcha::RecaptchaError do
        @controller.verify_recaptcha
      end
    end

    it "returns false when secret key is invalid" do
      expect_http_post.to_return(body: %({"foo":"false", "bar":"invalid-site-secret-key"}))

      refute @controller.verify_recaptcha
      assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
    end

    it "adds an error to the model" do
      expect_http_post.to_return(body: %({"foo":"false", "bar":"bad-news"}))

      errors = mock
      errors.expects(:add).with(:base, "reCAPTCHA verification failed, please try again.")
      model = mock(errors: errors)

      refute @controller.verify_recaptcha(model: model)
      assert_nil @controller.flash[:recaptcha_error]
    end

    it "returns true on success with optional key" do
      key = 'ADIFFERENTPRIVATEKEYXXXXXXXXXXXXXX'
      @controller.flash[:recaptcha_error] = "previous error that should be cleared"
      expect_http_post(secret_key: key).to_return(body: '{"success":true}')

      assert @controller.verify_recaptcha(secret_key: key)
      assert_nil @controller.flash[:recaptcha_error]
    end

    it "returns true on success without remote_ip" do
      @controller.flash[:recaptcha_error] = "previous error that should be cleared"
      secret_key = Recaptcha.configuration.secret_key
      stub_request(
        :get,
        "https://www.recaptcha.net/recaptcha/api/siteverify?response=string&secret=#{secret_key}"
      ).to_return(body: '{"success":true}')

      assert @controller.verify_recaptcha(skip_remote_ip: true)
      assert_nil @controller.flash[:recaptcha_error]
    end

    it "fails silently when timing out" do
      expect_http_post.to_timeout
      refute @controller.verify_recaptcha
      @controller.flash[:recaptcha_error].must_equal(
        "Oops, we failed to validate your reCAPTCHA response. Please try again."
      )
    end

    it "blows up on timeout when graceful is disabled" do
      Recaptcha.with_configuration(handle_timeouts_gracefully: false) do
        expect_http_post.to_timeout
        assert_raises Recaptcha::RecaptchaError, "Recaptcha unreachable." do
          assert @controller.verify_recaptcha
        end
        assert_nil @controller.flash[:recaptcha_error]
      end
    end

    it "uses I18n for the failed message" do
      I18n.locale = :de
      verification_failed_translated   = "Sicherheitscode konnte nicht verifiziert werden."
      verification_failed_default      = "reCAPTCHA verification failed, please try again."

      I18n.expects(:translate).
        with('recaptcha.errors.verification_failed', default: verification_failed_default).
        returns(verification_failed_translated)

      errors = mock
      errors.expects(:add).with(:base, verification_failed_translated)
      model = mock
      model.stubs(errors: errors)

      expect_http_post.to_return(body: %({"foo":"false", "bar":"bad-news"}))
      @controller.verify_recaptcha(model: model)
    end

    it "uses I18n for the timeout message" do
      I18n.locale = :de
      recaptcha_unreachable_translated = "Netzwerkfehler, bitte versuchen Sie es später erneut."
      recaptcha_unreachable_default    = "Oops, we failed to validate your reCAPTCHA response. Please try again."

      I18n.expects(:translate).
        with('recaptcha.errors.recaptcha_unreachable', default: recaptcha_unreachable_default).
        returns(recaptcha_unreachable_translated)

      errors = mock
      errors.expects(:add).with(:base, recaptcha_unreachable_translated)
      model = mock
      model.stubs(errors: errors)

      expect_http_post.to_timeout
      @controller.verify_recaptcha(model: model)
    end

    it "translates api response with I18n" do
      api_error_translated = "Bad news, body :("
      expect_http_post.to_return(body: %({"foo":"false", "bar":"bad-news"}))
      I18n.expects(:translate).
        with('recaptcha.errors.verification_failed', default: 'reCAPTCHA verification failed, please try again.').
        returns(api_error_translated)

      refute @controller.verify_recaptcha
      assert_equal api_error_translated, @controller.flash[:recaptcha_error]
    end

    it "falls back to api response if i18n translation is missing" do
      expect_http_post.to_return(body: %({"foo":"false", "bar":"bad-news"}))

      refute @controller.verify_recaptcha
      assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
    end

    it "does not flash error when request was not html" do
      @controller.request = stub(remote_ip: "1.1.1.1", format: :json)
      expect_http_post.to_return(body: %({"foo":"false", "bar":"bad-news"}))
      refute @controller.verify_recaptcha
      assert_nil @controller.flash[:recaptcha_error]
    end

    it "does not verify via http call when user did not click anything" do
      @controller.params = { 'g-recaptcha-response' => ""}
      assert_not_requested :get, %r{\.google\.com}
      assert_equal false, @controller.verify_recaptcha
      assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
    end

    it "does not verify via http call when response length exceeds G_RESPONSE_LIMIT" do
      # this returns a 400 or 413 instead of a 200 response with error code
      # typical response length is less than 400 characters
      str = "a" * 4001
      @controller.params = { 'g-recaptcha-response' => "#{str}"}
      assert_not_requested :get, %r{\.google\.com}
      assert_equal false, @controller.verify_recaptcha
      assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
    end

    describe ':hostname' do
      let(:hostname) { 'fake.hostname.com' }

      before do
        expect_http_post.to_return(body: %({"success":true, "hostname": "#{hostname}"}))
      end

      it "passes with nil" do
        assert @controller.verify_recaptcha(hostname: nil)
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "passes with false" do
        assert @controller.verify_recaptcha(hostname: false)
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "check for equality when string custom hostname validation is passed" do
        assert @controller.verify_recaptcha(hostname: hostname)
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "fails when custom hostname validation does not match" do
        expect_http_post.to_return(body: %({"success":true, "hostname": "not_#{hostname}"}))

        refute @controller.verify_recaptcha(hostname: hostname)
        assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
      end

      it "check with call when callable custom hostname validation is passed" do
        assert @controller.verify_recaptcha(hostname: -> (d) { d == hostname })
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "raises when invalid custom hostname validation is passed" do
        assert_raises Recaptcha::RecaptchaError do
          @controller.verify_recaptcha(hostname: 0)
        end
      end

      describe "when default hostname validation matches" do
        around { |test| Recaptcha.with_configuration(hostname: hostname, &test) }

        it "passes" do
          assert @controller.verify_recaptcha
          assert_nil @controller.flash[:recaptcha_error]
        end

        it "fails when custom validation does not match" do
          refute @controller.verify_recaptcha(hostname: "not_#{hostname}")
          assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
        end
      end

      describe "when default hostname validation does not match" do
        around { |test| Recaptcha.with_configuration(hostname: "not_#{hostname}", &test) }

        it "fails" do
          refute @controller.verify_recaptcha
          assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
        end

        it "passes when custom validation matches" do
          assert @controller.verify_recaptcha(hostname: hostname)
          assert_nil @controller.flash[:recaptcha_error]
        end
      end
    end

    describe 'action_valid?' do
      let(:default_response_hash) { {
        success: true,
        action: 'homepage',
      } }

      before do
        expect_http_post.to_return(body: success_body)
      end

      it "fails when action from response does not match expected action" do
        expect_http_post.to_return(body: success_body(action: "not_homepage"))

        refute verify_recaptcha(action: 'homepage')
        assert_flash_error
      end

      it "passes with string that matches" do
        assert verify_recaptcha(action: 'homepage')
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "passes with nil" do
        assert verify_recaptcha(action: nil)
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "passes with false" do
        assert verify_recaptcha(action: false)
        assert_nil @controller.flash[:recaptcha_error]
      end
    end

    describe 'score_above_threshold?' do
      let(:default_response_hash) { {
        success: true,
        action: 'homepage',
      } }

      before do
        expect_http_post.to_return(body: success_body(score: 0.4))
      end

      it "fails when score is below minimum_score" do
        refute verify_recaptcha(minimum_score: 0.5)
        assert_flash_error
      end

      it "fails when response doesn't include a score" do
        expect_http_post.to_return(body: success_body())
        refute verify_recaptcha(minimum_score: 0.4)
        assert_flash_error
      end

      it "passes with score exactly at minimum_score" do
        assert verify_recaptcha(minimum_score: 0.4)
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "passes when minimum_score not specified or nil" do
        assert verify_recaptcha()
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "passes with false" do
        assert verify_recaptcha(minimum_score: false)
        assert_nil @controller.flash[:recaptcha_error]
      end
    end
  end

  describe "#recatcha_reply" do
    let(:default_response_hash) { {
      success: true,
      score: 0.97,
      action: 'homepage',
    } }

    before do
      expect_http_post.to_return(body: success_body)
    end

    it "is initially nil" do
      assert_nil @controller.recaptcha_reply
    end

    it "contains the recaptcha reply once verify_recaptcha has been called" do
      assert verify_recaptcha()
      assert_equal default_response_hash.to_json, @controller.recaptcha_reply.to_json
    end
  end

  private

  class TestController
    include Recaptcha::Adapters::ControllerMethods

    attr_accessor :request, :params, :flash

    def initialize
      @flash = {}
    end

    public :verify_recaptcha
    public :verify_recaptcha!
    public :recaptcha_reply
  end

  def expect_http_post(secret_key: Recaptcha.configuration.secret_key)
    stub_request(
      :get,
      "https://www.recaptcha.net/recaptcha/api/siteverify?remoteip=1.1.1.1&response=string&secret=#{secret_key}"
    )
  end

  def success_body(other = {})
    default_response_hash.
      merge(other).
      to_json
  end

  def error_body(error_code = "bad-news")
    { "error-codes" => [error_code] }.
      to_json
  end

  def verify_recaptcha(options = {})
    options[:action] = 'homepage' unless options.key?(:action)
    @controller.verify_recaptcha(options)
  end

  def assert_flash_error
    assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
  end
end
