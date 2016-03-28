require_relative 'helper'

describe Recaptcha::Verify do
  before do
    @controller = TestController.new
    @controller.request = stub(:remote_ip => "1.1.1.1", format: :html)

    @expected_post_data = {}
    @expected_post_data["remoteip"]   = @controller.request.remote_ip
    @expected_post_data["response"]   = "response"

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
      @controller.flash[:recaptcha_error] = "previous error that should be cleared"
      expect_http_post.to_return(body: '{"success":true}')

      assert @controller.verify_recaptcha
      assert_nil @controller.flash[:recaptcha_error]
    end

    it "raises without private key" do
      Recaptcha.configuration.private_key = nil
      assert_raises Recaptcha::RecaptchaError do
        @controller.verify_recaptcha
      end
    end

    it "returns false when private key is invalid" do
      expect_http_post.to_return(body: %{{"foo":"false", "bar":"invalid-site-private-key"}})

      refute @controller.verify_recaptcha
      assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
    end

    it "adds an error to the model" do
      expect_http_post.to_return(body: %{{"foo":"false", "bar":"bad-news"}})

      errors = mock
      errors.expects(:add).with(:base, "reCAPTCHA verification failed, please try again.")
      model = mock(:errors => errors)

      refute @controller.verify_recaptcha(:model => model)
      assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
    end

    it "returns true on success with optional key" do
      key = 'ADIFFERENTPRIVATEKEYXXXXXXXXXXXXXX'
      @controller.flash[:recaptcha_error] = "previous error that should be cleared"
      expect_http_post(private_key: key).to_return(body: '{"success":true}')

      assert @controller.verify_recaptcha(private_key: key)
      assert_nil @controller.flash[:recaptcha_error]
    end

    it "fails silently when timing out" do
      expect_http_post.to_timeout
      refute @controller.verify_recaptcha
      assert_equal "Oops, we failed to validate your reCAPTCHA response. Please try again.", @controller.flash[:recaptcha_error]
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

      I18n.expects(:translate).with('recaptcha.errors.verification_failed', :default => verification_failed_default).returns(verification_failed_translated)

      errors = mock
      errors.expects(:add).with(:base, verification_failed_translated)
      model  = mock
      model.stubs(:errors => errors)

      expect_http_post.to_return(body: %{{"foo":"false", "bar":"bad-news"}})
      @controller.verify_recaptcha(:model => model)
    end

    it "uses I18n for the timeout message" do
      I18n.locale = :de
      recaptcha_unreachable_translated = "Netzwerkfehler, bitte versuchen Sie es später erneut."
      recaptcha_unreachable_default    = "Oops, we failed to validate your reCAPTCHA response. Please try again."

      I18n.expects(:translate).with('recaptcha.errors.recaptcha_unreachable', :default => recaptcha_unreachable_default).returns(recaptcha_unreachable_translated)

      errors = mock
      errors.expects(:add).with(:base, recaptcha_unreachable_translated)
      model  = mock
      model.stubs(:errors => errors)

      expect_http_post.to_timeout
      @controller.verify_recaptcha(:model => model)
    end

    it "translates api response with I18n" do
      api_error_translated = "Bad news, body :("
      expect_http_post.to_return(body: %{{"foo":"false", "bar":"bad-news"}})
      I18n.expects(:translate).with('recaptcha.errors.verification_failed', :default => 'reCAPTCHA verification failed, please try again.').returns(api_error_translated)

      refute @controller.verify_recaptcha
      assert_equal api_error_translated, @controller.flash[:recaptcha_error]
    end

    it "falls back to api respnse if i18n translation is missing" do
      expect_http_post.to_return(body: %{{"foo":"false", "bar":"bad-news"}})

      refute @controller.verify_recaptcha
      assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
    end

    it "does not flash error when request was not html" do
      @controller.request = stub(:remote_ip => "1.1.1.1", format: :json)
      expect_http_post.to_return(body: %{{"foo":"false", "bar":"bad-news"}})
      refute @controller.verify_recaptcha
      assert_nil @controller.flash[:recaptcha_error]
    end

    it "check for equality when string custom domain validation is passed" do
      domain = 'fake.domain.com'

      expect_http_post.to_return(body: %{{"success":true, "hostname": "#{domain}"}})

      assert @controller.verify_recaptcha(domain: domain)
      assert_nil @controller.flash[:recaptcha_error]
    end

    it "fails when custom domain validation does not match" do
      expect_http_post.to_return(body: %{{"success":true, "hostname": "fake.domain.com"}})

      refute @controller.verify_recaptcha(domain: 'fake.hostname.com')
      assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
    end

    it "check with call when callable custom domain validation is passed" do
      fake_domain = 'fake.domain.com'

      domain = -> (d) { d == fake_domain }

      expect_http_post.to_return(body: %{{"success":true, "hostname": "#{fake_domain}"}})

      assert @controller.verify_recaptcha(domain: domain)
      assert_nil @controller.flash[:recaptcha_error]
    end

    it "railses when invalid custom domain validation is passed" do
      domain = 0

      expect_http_post.to_return(body: %{{"success":true, "hostname": "fake.domain.com"}})

      assert_raises Recaptcha::RecaptchaError do
        @controller.verify_recaptcha(domain: domain)
      end
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

  def expect_http_post(private_key: Recaptcha.configuration.private_key)
    stub_request(:get, "https://www.google.com/recaptcha/api/siteverify?remoteip=1.1.1.1&response=&secret=#{private_key}")
  end
end
