# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

module Recaptcha
  module Verify
    # Represents the result of us verifying that the verify response is valid against our
    # {Configuration}.
    #
    # This is mostly a wrapper for {VerifyResponse} but depends also upon comparing it to our
    # configured hostname, etc.
    #
    class Result
      attr_reader :response
      attr_reader :errors

      def initialize(verify_response, expected_hostname: nil, expected_action: nil, minimum_score: nil)
        @response = verify_response
        @expected_hostname = expected_hostname || Recaptcha.configuration.hostname
        @expected_action = expected_action
        @minimum_score = minimum_score
        check_validations
      end

      delegate :json, :challenge_ts, :hostname,
        :score, :action,
        :error_codes, :timeout_or_duplicate?,
        to: :response, allow_nil: true

      # Returns true if the API response was successful *and* it passes all internal (app-defined)
      # validations, else false. You can check `errors` to see which validation failed if success?
      # returns false.
      def success?
        @errors.none?
      end
      alias_method :valid?, :success?

      def hostname_valid?
        case @expected_hostname
        when nil, FalseClass then true
        when String then @expected_hostname == hostname
        else @expected_hostname.call(hostname)
        end
      end

      def hostname_invalid?
        !hostname_valid?
      end

      def action_valid?
        case @expected_action
        when nil, FalseClass then true
        else action == @expected_action
        end
      end

      def action_invalid?
        !action_valid?
      end

      # Returns true iff score is greater or equal to (>=) minimum_score, or if no minimum_score was specified
      def score_above_threshold?
        return true if score.nil?

        case @minimum_score
        when nil, FalseClass then true
        else score >= @minimum_score
        end
      end

      def score_below_threshold?
        !score_above_threshold?
      end

      private

      def check_validations
        @errors = []
        return false unless validate_response

        validate_hostname
        validate_action
        validate_score_above_threshold
      end

      def validate_response
        unless response&.success?
          @errors.concat error_codes if error_codes
          false
        end
        true
      end

      def validate_hostname
        unless hostname_valid?
          @errors << "Hostname '#{hostname}' did not match expected hostname"
        end
      end

      def validate_action
        unless action_valid?
          @errors << "Action '#{action}' did not match '#{@expected_action}'"
        end
      end

      def validate_score_above_threshold
        unless score_above_threshold?
          @errors << "Score was below minimum score"
        end
      end
    end

    class ErrorResult < Result
      def initialize(error_message)
        super(nil)
        @errors = [error_message]
      end

      def success?
        false
      end
    end

    class MissingResponseTokenErrorResult < ErrorResult
      def initialize
        super('missing response token')
      end
    end

    class ResponseTokenTooLongErrorResult < ErrorResult
      def initialize(length)
        max_length = G_RESPONSE_LIMIT
        super("response token was too long (#{length} > #{max_length})")
      end
    end

    class TimeoutErrorResult < ErrorResult
      def initialize
        super('timed out')
      end
    end
  end
end
