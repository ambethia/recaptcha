module VerifyCommon
  def self.call
    describe "#verify_recaptcha" do
      it "raises without secret key" do
        Recaptcha.configuration.secret_key = nil
        assert_raises Recaptcha::RecaptchaError do
          verify_recaptcha
        end
      end

      it "when secret key is invalid" do
        expect_http_post.to_return(body: error_body("invalid-site-secret-key"))

        assert_result_error verify_recaptcha, 'invalid-site-secret-key'
        assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
      end

      it "adds an error to the model" do
        expect_http_post.to_return(body: error_body)

        errors = mock
        errors.expects(:add).with(:base, "reCAPTCHA verification failed, please try again.")
        model = mock(errors: errors)

        assert_result_error verify_recaptcha(model: model), 'bad-news'
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "success with optional key" do
        key = 'ADIFFERENTPRIVATEKEYXXXXXXXXXXXXXX'
        @controller.flash[:recaptcha_error] = "previous error that should be cleared"
        expect_http_post(secret_key: key).to_return(body: success_body)

        assert_valid_result verify_recaptcha(secret_key: key)
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "success without remote_ip" do
        @controller.flash[:recaptcha_error] = "previous error that should be cleared"
        secret_key = Recaptcha.configuration.secret_key
        stub_request(
          :get,
          "https://www.google.com/recaptcha/api/siteverify?response=string&secret=#{secret_key}"
        ).to_return(body: success_body)

        assert_valid_result verify_recaptcha(skip_remote_ip: true)
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "makes full result available as @controller.recaptcha_verify_result" do
        expect_http_post.to_return(body: success_body)

        assert_valid_result verify_recaptcha
        assert @controller.recaptcha_verify_result.is_a?(Recaptcha::Verify::Result)
        assert @controller.recaptcha_verify_result.valid?
      end

      it "fails silently when timing out" do
        expect_http_post.to_timeout
        assert_result_error verify_recaptcha, 'timed out'
        @controller.flash[:recaptcha_error].must_equal(
          "Oops, we failed to validate your reCAPTCHA response. Please try again."
        )
      end

      it "raises on timeout when graceful is disabled" do
        Recaptcha.with_configuration(handle_timeouts_gracefully: false) do
          expect_http_post.to_timeout
          assert_raises Recaptcha::RecaptchaError, "Recaptcha unreachable." do
            assert verify_recaptcha
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

        expect_http_post.to_return(body: error_body)
        verify_recaptcha(model: model)
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
        verify_recaptcha(model: model)
      end

      it "translates api response with I18n" do
        api_error_translated = "Bad news, body :("
        expect_http_post.to_return(body: error_body)
        I18n.expects(:translate).
          with('recaptcha.errors.verification_failed', default: 'reCAPTCHA verification failed, please try again.').
          returns(api_error_translated)

        assert_result_error verify_recaptcha, 'bad-news'
        assert_equal api_error_translated, @controller.flash[:recaptcha_error]
      end

      it "falls back to api response if i18n translation is missing" do
        expect_http_post.to_return(body: error_body)

        assert_result_error verify_recaptcha, 'bad-news'
        assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
      end

      it "does not flash error when request was not html" do
        @controller.request = stub(remote_ip: "1.1.1.1", format: :json)
        expect_http_post.to_return(body: error_body)
        assert_result_error verify_recaptcha, 'bad-news'
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "does not verify via http call when user did not click anything" do
        @controller.params = { 'g-recaptcha-response' => ""}
        assert_not_requested :get, %r{\.google\.com}
        assert_result_error verify_recaptcha, 'missing response token'
        assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
      end

      it "does not verify via http call when response length exceeds G_RESPONSE_LIMIT" do
        # this returns a 400 or 413 instead of a 200 response with error code
        # typical response length is less than 400 characters
        str = "a" * 4001
        @controller.params = { 'g-recaptcha-response' => "#{str}"}
        assert_not_requested :get, %r{\.google\.com}
        assert_result_error verify_recaptcha, 'response token was too long (4001 > 4000)'
        assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
      end
    end

    describe 'Verify::Result#hostname_valid?' do
      let(:hostname) { 'fake.hostname.com' }

      before do
        expect_http_post.to_return(body: success_body(hostname: "#{hostname}"))
      end

      it "passes with nil" do
        assert verify_recaptcha(hostname: nil)
        assert_equal true, @controller.recaptcha_verify_result.hostname_valid?
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "passes with false" do
        assert verify_recaptcha(hostname: false)
        assert_equal true, @controller.recaptcha_verify_result.hostname_valid?
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "check for equality when string custom hostname validation is passed" do
        assert verify_recaptcha(hostname: hostname)
        assert_equal true, @controller.recaptcha_verify_result.hostname_valid?
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "fails when custom hostname validation does not match" do
        expect_http_post.to_return(body: success_body(hostname: "not_#{hostname}"))

        assert_result_error verify_recaptcha(hostname: hostname), "Hostname 'not_#{hostname}' did not match expected hostname"
        assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
        assert_equal false, @controller.recaptcha_verify_result.hostname_valid?
      end

      it "check with call when callable custom hostname validation is passed" do
        assert verify_recaptcha(hostname: -> (d) { d == hostname })
        assert_equal true, @controller.recaptcha_verify_result.hostname_valid?
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "raises when invalid custom hostname validation is passed" do
        assert_raises Recaptcha::RecaptchaError do
          verify_recaptcha(hostname: 0)
        end
      end

      describe "when default hostname validation matches" do
        around { |test| Recaptcha.with_configuration(hostname: hostname, &test) }

        it "passes" do
          assert verify_recaptcha
          assert_equal true, @controller.recaptcha_verify_result.hostname_valid?
          assert_nil @controller.flash[:recaptcha_error]
        end

        it "fails when custom validation does not match" do
          assert_result_error verify_recaptcha(hostname: "not_#{hostname}"), "Hostname 'fake.hostname.com' did not match expected hostname"
          assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
        end
      end

      describe "when default hostname validation does not match" do
        around { |test| Recaptcha.with_configuration(hostname: "not_#{hostname}", &test) }

        it "fails" do
          assert_result_error verify_recaptcha(hostname: "not_#{hostname}"), "Hostname 'fake.hostname.com' did not match expected hostname"
          assert_equal false, @controller.recaptcha_verify_result.send(:hostname_valid?)
          assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
        end

        it "passes when custom validation matches" do
          assert verify_recaptcha(hostname: hostname)
          assert_equal true, @controller.recaptcha_verify_result.hostname_valid?
          assert_nil @controller.flash[:recaptcha_error]
        end
      end
    end
  end
end
