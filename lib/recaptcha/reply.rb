module Recaptcha
  class Reply
    attr_reader :raw_reply, :enterprise

    def initialize(raw_reply, enterprise: false)
      @raw_reply = raw_reply
      @enterprise = enterprise
    end

    def [](key)
      return send(key.to_sym) if respond_to?(key.to_sym)

      raw_reply[key]
    end

    def token_properties
      raw_reply['tokenProperties'] if enterprise?
    end

    def success?
      success = if enterprise?
                  token_properties&.dig('valid')
                else
                  raw_reply['success']
                end

      success.to_s == 'true'
    end

    def hostname
      return raw_reply['hostname'] unless enterprise?

      token_properties&.dig('hostname')
    end

    def action
      return raw_reply['action'] unless enterprise?

      token_properties&.dig('action')
    end

    def score
      return raw_reply['score'] unless enterprise?

      raw_reply.dig('riskAnalysis', 'score')
    end

    def error_codes
      return [] if enterprise?

      raw_reply['error-codes'] || []
    end

    # Returns the challenge timestamp
    def challenge_ts
      return raw_reply['challenge_ts'] unless enterprise?

      token_properties&.dig('createTime')
    end

    def enterprise?
      @enterprise
    end

    def free?
      !enterprise?
    end

    def to_h
      raw_reply
    end

    def to_s
      raw_reply.to_s
    end

    def to_json(*args)
      raw_reply.to_json(*args)
    end
  end
end
