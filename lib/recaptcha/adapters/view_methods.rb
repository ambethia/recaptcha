# frozen_string_literal: true

module Recaptcha
  module Adapters
    module ViewMethods
      # Your public API can be specified in the +options+ hash or preferably
      # using the Configuration.
      def recaptcha_tags(options = {})
        ::Recaptcha::Helpers.recaptcha_tags(options)
      end

      # Invisible reCAPTCHA implementation
      def invisible_recaptcha_tags(options = {})
        ::Recaptcha::Helpers.invisible_recaptcha_tags(options)
      end
    end
  end
end
