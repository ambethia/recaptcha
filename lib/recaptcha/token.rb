require 'json'
require 'recaptcha'
require 'base64'
require 'securerandom'
require 'openssl'

module Recaptcha
  module Token

    def self.secure_token
      private_key  =  Recaptcha.configuration.private_key
      raise RecaptchaError, "No private key specified." unless private_key

      stoken_json = {'session_id' => SecureRandom.uuid, 'ts_ms' => (Time.now.to_f * 1000).to_i}.to_json
      cipher = OpenSSL::Cipher::AES128.new(:ECB)
      private_key_digest = Digest::SHA1.digest(private_key)[0...16]

      cipher.encrypt
      cipher.key = private_key_digest
      encrypted_stoken = cipher.update(stoken_json) << cipher.final
      Base64.urlsafe_encode64(encrypted_stoken).gsub(/\=+\Z/, '')
    end
  end
end
