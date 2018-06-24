# frozen_string_literal: true

module Recaptcha
  class Railtie < Rails::Railtie
    ActiveSupport.on_load(:action_view) do
      require 'recaptcha/client_helper'
      include Recaptcha::ClientHelper
    end

    ActiveSupport.on_load(:action_controller) do
      require 'recaptcha/verify'
      include Recaptcha::Verify
    end
  end
end
