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

  it "cleans up block configuration after block raises an exception" do
    outside = '0000000000000000000000000000000000000000'
    Recaptcha.configuration.public_key.must_equal outside

    begin
      Recaptcha.with_configuration(public_key: '12345') do
        Recaptcha.configuration.public_key.must_equal '12345'
        raise "an exception"
      end
    rescue => e
    end

    Recaptcha.configuration.public_key.must_equal outside
  end

  describe "#api_version=" do
    it "warns when assigning v2" do
      Recaptcha.configuration.expects(:warn)
      Recaptcha.configuration.api_version = "v2"
    end

    it "raises when assigning v1" do
      assert_raises ArgumentError do
        Recaptcha.configuration.api_version = "v1"
      end
    end
  end

  describe "#api_version" do
    it "warns" do
      Recaptcha.configuration.expects(:warn)
      Recaptcha.configuration.api_version.must_equal "v2"
    end
  end
end
