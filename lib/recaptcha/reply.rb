module Recaptcha
  class Reply
    def initialize(raw_reply, enterprise: false)
      @raw_reply = raw_reply
      @enterprise = enterprise
    end

    def token_properties
      @raw_reply['tokenProperties'] if enterprise?
    end

    def success?(options = {})
      result = success.to_s == 'true' &&
        hostname_valid?(options[:hostname]) &&
        action_valid?(options[:action]) &&
        score_above_threshold?(options[:minimum_score]) &&
        score_below_threshold?(options[:maximum_score])

      if options[:with_reply] == true
        [result, self]
      else
        result
      end
    end

    def success
      return @raw_reply['success'] unless enterprise?

      token_properties&.dig('valid')
    end

    def hostname
      return @raw_reply['hostname'] unless enterprise?

      token_properties&.dig('hostname')
    end

    def action
      return @raw_reply['action'] unless enterprise?

      token_properties&.dig('action')
    end

    def score
      return @raw_reply['score'] unless enterprise?

      @raw_reply.dig('riskAnalysis', 'score')
    end

    def error_codes
      return [] if enterprise?

      @raw_reply['error-codes'] || []
    end

    def error_codes?
      !error_codes.empty?
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

    def free?
      !enterprise?
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
