# frozen_string_literal: true

module Recaptcha
  module Verify
    # Represents a response from the Recaptcha verify API
    class Response
      attr_reader :http_response

      # @param [Net::HTTPResponse]
      def initialize(http_response)
        @http_response = http_response
      end

      # @return [Hash] The JSON response
      #
      # For [v2](https://developers.google.com/recaptcha/docs/verify#api-response):
      #
      # {
      #   "success": true|false,
      #   "challenge_ts": timestamp,  // timestamp of the challenge load (ISO format yyyy-MM-dd'T'HH:mm:ssZZ)
      #   "hostname": string,         // the hostname of the site where the reCAPTCHA was solved
      #   "error-codes": [...]        // optional
      # }
      #
      # For [v3](https://developers.google.com/recaptcha/docs/v3#site-verify-response):
      #
      # {
      #   "success": true|false,      // whether this request was a valid reCAPTCHA token for your site
      #   "score": number             // the score for this request (0.0 - 1.0)
      #   "action": string            // the action name for this request (important to verify)
      #   "challenge_ts": timestamp,  // timestamp of the challenge load (ISO format yyyy-MM-dd'T'HH:mm:ssZZ)
      #   "hostname": string,         // the hostname of the site where the reCAPTCHA was solved
      #   "error-codes": [...]        // optional
      # }
      #
      def json
        @json ||= JSON.parse(@http_response.body)
      end

      def success?
        json['success'].to_s == 'true'
      end

      def score
        json['score']
      end

      def action
        json['action']
      end

      def challenge_ts
        json['challenge_ts']
      end

      def hostname
        json['hostname']
      end

      def error_codes
        json['error-codes']
      end

      def timeout_or_duplicate?
        error_codes&.include? 'timeout-or-duplicate'
      end
    end
  end
end
