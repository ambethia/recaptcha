# frozen_string_literal: true

require 'json'

module Recaptcha
  module Verify
    G_RESPONSE_LIMIT = 4000

    def self.skip?(env)
      env ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || (Rails.env if defined? Rails.env)
      Recaptcha.configuration.skip_verify_env.include? env
    end

    def self.invalid_response?(resp)
      resp.empty? || resp.length > G_RESPONSE_LIMIT
    end

    def self.verify_via_api_call(response, options)
      secret_key = options.fetch(:secret_key) { Recaptcha.configuration.secret_key! }
      verify_hash = { 'secret' => secret_key, 'response' => response }
      verify_hash['remoteip'] = options[:remote_ip] if options.key?(:remote_ip)

      reply = JSON.parse(Recaptcha.get(verify_hash, options))
      reply['success'].to_s == 'true' &&
        hostname_valid?(reply['hostname'], options[:hostname])
    end

    def self.hostname_valid?(hostname, validation)
      validation ||= Recaptcha.configuration.hostname

      case validation
      when nil, FalseClass then true
      when String then validation == hostname
      else validation.call(hostname)
      end
    end
  end
end
