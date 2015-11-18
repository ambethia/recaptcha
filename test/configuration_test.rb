require_relative 'helper'

describe Recaptcha::Configuration do
  it "uses default version" do
    assert_equal(Recaptcha.configuration.api_version, Recaptcha::RECAPTCHA_API_VERSION)
  end

  it "knows it is v1" do
    Recaptcha.configuration.api_version = 'v1'
    assert Recaptcha.configuration.v1?
    refute Recaptcha.configuration.v2?
  end

  it "knows it is v2" do
    assert Recaptcha.configuration.v2?
    refute Recaptcha.configuration.v1?
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
