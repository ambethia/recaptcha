# frozen_string_literal: true

module Recaptcha
  class Reply
    def initialize(raw_reply, enterprise:)
      @raw_reply = raw_reply
      @enterprise = enterprise
    end

    def [](key)
      @raw_reply[key.to_s]
    end

    def success?(options = {})
      success.to_s == 'true' &&
        hostname_valid?(options[:hostname]) &&
        action_valid?(options[:action]) &&
        score_above_threshold?(options[:minimum_score]) &&
        score_below_threshold?(options[:maximum_score])
    end

    def token_properties
      @raw_reply['tokenProperties'] if enterprise?
    end

    def success
      if enterprise?
        token_properties&.dig('valid')
      else
        @raw_reply['success']
      end
    end

    def hostname
      if enterprise?
        token_properties&.dig('hostname')
      else
        @raw_reply['hostname']
      end
    end

    def action
      if enterprise?
        token_properties&.dig('action')
      else
        @raw_reply['action']
      end
    end

    def score
      if enterprise?
        @raw_reply.dig('riskAnalysis', 'score')
      else
        @raw_reply['score'] unless enterprise?
      end
    end

    def error_codes
      if enterprise?
        []
      else
        @raw_reply['error-codes'] || []
      end
    end

    def challenge_ts
      return @raw_reply['challenge_ts'] unless enterprise?

      token_properties&.dig('createTime')
    end

    def hostname_valid?(validation)
      validation ||= Recaptcha.configuration.hostname

      case validation
      when nil, FalseClass
        true
      when String
        validation == hostname
      else
        validation.call(hostname)
      end
    end

    def action_valid?(expected_action)
      case expected_action
      when nil, FalseClass
        true
      else
        action == expected_action.to_s
      end
    end

    def score_above_threshold?(minimum_score)
      !minimum_score || (score && score >= minimum_score)
    end

    def score_below_threshold?(maximum_score)
      !maximum_score || (score && score <= maximum_score)
    end

    def enterprise?
      @enterprise
    end

    def to_h
      @raw_reply
    end

    def to_s
      @raw_reply.to_s
    end

    def to_json(*args)
      @raw_reply.to_json(*args)
    end
  end
end
