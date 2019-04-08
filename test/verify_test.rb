require_relative 'helper'
require_relative 'verify_common'

describe Recaptcha::Verify do
  before do
    @controller = TestController.new
    @controller.request = stub(
      remote_ip: "1.1.1.1",
      format: :html
    )
    @controller.params = {
      'g-recaptcha-response' => 'string'
    }
  end

  describe 'v2' do
    VerifyCommon.call

#    describe "#verify_recaptcha" do
#      it "returns true on success" do
#        @controller.flash[:recaptcha_error] = "previous error that should be cleared"
#        expect_http_post.to_return(body: success_body)
#
#        assert verify_recaptcha
#        assert_nil @controller.flash[:recaptcha_error]
#      end
#
#      it "verify_recaptcha_v2 is an alias for verify_recaptcha" do
#        @controller.flash[:recaptcha_error] = "previous error that should be cleared"
#        expect_http_post.to_return(body: success_body)
#
#        assert @controller.verify_recaptcha_v2
#        assert_nil @controller.flash[:recaptcha_error]
#      end
#    end
#
#    describe "#verify_recaptcha!" do
#      it "raises when it fails" do
#        @controller.expects(:verify_recaptcha).returns(false)
#
#        assert_raises Recaptcha::Verify::VerifyError do
#          @controller.verify_recaptcha!
#        end
#      end
#
#      it "returns a value when it passes" do
#        @controller.expects(:verify_recaptcha).returns(:foo)
#
#        assert_equal :foo, @controller.verify_recaptcha!
#      end
#    end

    def verify_recaptcha(options = {})
      @controller.verify_recaptcha(options)
    end

    def assert_valid_result(result)
      assert result

      result = @controller.recaptcha_verify_result
      assert result.valid?
      assert_equal [], result.errors
    end

    def assert_result_error(result, expected_error)
      refute result

      result = @controller.recaptcha_verify_result
      refute result.valid?
      assert result.errors.length > 0
      result.errors.must_include expected_error
    end

    let(:default_response_hash) { {
      success: true,
    } }
  end

  describe 'v3' do
    VerifyCommon.call

    describe "#verify_recaptcha_v3" do
      it "returns a Verify::Result on success" do
        @controller.flash[:recaptcha_error] = "previous error that should be cleared"
        expect_http_post.to_return(body: success_body)

        assert verify_recaptcha.is_a?(Recaptcha::Verify::Result)
        assert verify_recaptcha.action_valid?
        assert_nil @controller.flash[:recaptcha_error]
      end

      it "gets the param using action as a key" do
        expect_http_post.to_return(body: success_body)
        @controller.params['g-recaptcha-response'] = {
          'homepage' => "string",
          'action/b' => "response_b"
        }

        assert_equal 'string', @controller.send(:get_response_token_for_action, 'homepage')
        assert verify_recaptcha(action: 'homepage')
      end


      describe 'Verify::Result#action_valid?' do
        before do
          expect_http_post.to_return(body: success_body)
        end

        it "fails when action from response does not match expected action" do
          expect_http_post.to_return(body: success_body(action: "not_homepage"))

          assert_result_error verify_recaptcha(action: 'homepage'), "Action 'not_homepage' did not match 'homepage'"
          assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
        end

        it "passes with string that matches" do
          assert verify_recaptcha(action: 'homepage')
          assert_equal true, @controller.recaptcha_verify_result.action_valid?
          assert_nil @controller.flash[:recaptcha_error]
        end

        it "passes with nil" do
          assert verify_recaptcha(action: nil)
          assert_equal true, @controller.recaptcha_verify_result.action_valid?
          assert_nil @controller.flash[:recaptcha_error]
        end

        it "passes with false" do
          assert verify_recaptcha(action: false)
          assert_equal true, @controller.recaptcha_verify_result.action_valid?
          assert_nil @controller.flash[:recaptcha_error]
        end
      end

      describe 'Verify::Result#score_above_threshold?' do
        before do
          expect_http_post.to_return(body: success_body(score: 0.4))
        end

        it "fails when score is below minimum_score" do
          result = verify_recaptcha(minimum_score: 0.5)
          assert_result_error result, "Score was below minimum score"
          assert_equal false, result.score_above_threshold?
          assert_equal true,  result.score_below_threshold?
          assert_equal "reCAPTCHA verification failed, please try again.", @controller.flash[:recaptcha_error]
        end

        it "passes with score exactly at minimum_score" do
          assert verify_recaptcha(minimum_score: 0.4)
          assert_equal true, @controller.recaptcha_verify_result.score_above_threshold?
          assert_nil @controller.flash[:recaptcha_error]
        end

        it "passes when response doesn't include a score" do
          expect_http_post.to_return(body: success_body())
          assert verify_recaptcha(minimum_score: 0.4)
          assert_equal true, @controller.recaptcha_verify_result.score_above_threshold?
          assert_nil @controller.flash[:recaptcha_error]
        end

        it "passes with nil" do
          assert verify_recaptcha(minimum_score: nil)
          assert_equal true, @controller.recaptcha_verify_result.score_above_threshold?
          assert_nil @controller.flash[:recaptcha_error]
        end

        it "passes with false" do
          assert verify_recaptcha(minimum_score: false)
          assert_equal true, @controller.recaptcha_verify_result.score_above_threshold?
          assert_nil @controller.flash[:recaptcha_error]
        end
      end
    end

    describe "#verify_recaptcha_v3!" do
      it "raises when it fails" do
        @controller.expects(:verify_recaptcha_v3).returns(false)

        assert_raises Recaptcha::Verify::VerifyError do
          @controller.verify_recaptcha_v3!
        end
      end

      it "returns a Recaptcha::Verify::Result when it succeeds" do
        result = stub(valid?: true)
        @controller.expects(:verify_recaptcha_v3).returns(result)

        assert_equal result, @controller.verify_recaptcha_v3!
      end
    end

    def verify_recaptcha(options = {})
      options[:action] = 'homepage' unless options.key?(:action)
      @controller.verify_recaptcha_v3(options)
    end

    def assert_valid_result(result)
      assert result.valid?
      assert_equal [], result.errors
    end

    def assert_result_error(result, expected_error)
      refute result.valid?
      assert result.errors.length > 0
      assert result.errors.include?(expected_error)
      assert_equal result, @controller.recaptcha_verify_result
    end

    let(:default_response_hash) { {
      success: true,
      action: 'homepage',
    } }
  end

  private

  class TestController
    include Recaptcha::Verify
    attr_accessor :request, :params, :flash

    def initialize
      @flash = {}
    end
  end

  def expect_http_post(secret_key: Recaptcha.configuration.secret_key)
    stub_request(
      :get,
      "https://www.google.com/recaptcha/api/siteverify?remoteip=1.1.1.1&response=string&secret=#{secret_key}"
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
end
