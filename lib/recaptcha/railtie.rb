# frozen_string_literal: true

module Recaptcha
  class Railtie < Rails::Railtie
    ActiveSupport.on_load(:action_view) do
      include Recaptcha::Adapters::View
    end

    ActiveSupport.on_load(:action_controller) do
      include Recaptcha::Adapters::Controller
    end
  end
end
