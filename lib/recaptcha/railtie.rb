module Recaptcha
  class Railtie < Rails::Railtie
    initializer :recaptcha do
      ActiveSupport.on_load(:action_view) do
        require 'recaptcha/client_helper'
        include Recaptcha::ClientHelper
      end

      ActiveSupport.on_load(:action_view) do
        require 'recaptcha/verify'
        include Recaptcha::Verify
      end
    end
  end
end
