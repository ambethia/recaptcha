require_relative 'helper'

describe Recaptcha::Configuration do
  describe "#api_server_url" do
    it "serves the default" do
      Recaptcha.configuration.api_server_url.must_equal "https://www.recaptcha.net/recaptcha/api.js"
    end

    describe "when api_server_url is overwritten" do
      it "serves the overwritten url" do
        proxied_api_server_url = 'https://127.0.0.1:8080/recaptcha/api.js'
        Recaptcha.with_configuration(api_server_url: proxied_api_server_url) do
          Recaptcha.configuration.api_server_url.must_equal proxied_api_server_url
        end
      end
    end
  end

  describe "#verify_url" do
    it "serves the default" do
      Recaptcha.configuration.verify_url.must_equal "https://www.recaptcha.net/recaptcha/api/siteverify"
    end

    describe "when api_server_url is overwritten" do
      it "serves the overwritten url" do
        proxied_verify_url = 'https://127.0.0.1:8080/recaptcha/api/siteverify'
        Recaptcha.with_configuration(verify_url: proxied_verify_url) do
          Recaptcha.configuration.verify_url.must_equal proxied_verify_url
        end
      end
    end
  end

  it "can overwrite configuration in a block" do
    outside = '0000000000000000000000000000000000000000'
    Recaptcha.configuration.site_key.must_equal outside

    Recaptcha.with_configuration(site_key: '12345') do
      Recaptcha.configuration.site_key.must_equal '12345'
    end

    Recaptcha.configuration.site_key.must_equal outside
  end

  it "cleans up block configuration after block raises an exception" do
    before = Recaptcha.configuration.site_key.dup

    assert_raises NoMemoryError do
      Recaptcha.with_configuration(site_key: '12345') do
        Recaptcha.configuration.site_key.must_equal '12345'
        raise NoMemoryError, "an exception"
      end
    end

    Recaptcha.configuration.site_key.must_equal before
  end
end
