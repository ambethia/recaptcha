require_relative 'helper'

describe Recaptcha::Configuration do
  describe "#api_server_url" do
    it "serves the default" do
      Recaptcha.configuration.api_server_url.must_equal "https://www.google.com/recaptcha/api.js"
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
