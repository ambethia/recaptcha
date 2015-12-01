require 'recaptcha'

module Recaptcha
  class Railtie < Rails::Railtie
    initializer :recaptcha do
      ActionView::Base.send(:include, ::Recaptcha::ClientHelper)
      ActionController::Base.send(:include, ::Recaptcha::Verify)
    end
  end
end
