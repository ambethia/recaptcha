require_relative 'helper'

describe Recaptcha::Configuration do
  describe "#api_server_url" do
    it "serves the default" do
      Recaptcha.configuration.api_server_url.must_equal "//www.google.com/recaptcha/api.js"
    end

    it "servers the default for nil" do
      Recaptcha.configuration.api_server_url(ssl: nil).must_equal "//www.google.com/recaptcha/api.js"
    end

    it "knows ssl" do
      Recaptcha.configuration.api_server_url(ssl: true).must_equal "https://www.google.com/recaptcha/api.js"
    end

    it "knows non-ssl" do
      Recaptcha.configuration.api_server_url(ssl: false).must_equal "//www.google.com/recaptcha/api.js"
    end
  end

  it "can overwrite configuration in a block" do
    outside = '0000000000000000000000000000000000000000'
    Recaptcha.configuration.public_key.must_equal outside

    Recaptcha.with_configuration(public_key: '12345') do
      Recaptcha.configuration.public_key.must_equal '12345'
    end

    Recaptcha.configuration.public_key.must_equal outside
  end
end
