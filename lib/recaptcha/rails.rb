require 'net/http'
require 'recaptcha'

if defined? ActionView
  ActionView::Base.class_eval do
    include Recaptcha::ClientHelper
  end
end

if defined? ActionController
  ActionController::Base.class_eval do
    include Recaptcha::Verify
  end
end