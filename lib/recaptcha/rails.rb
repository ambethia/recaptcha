require 'recaptcha'

ActionView::Base.send(:include, Recaptcha::ClientHelper)
ActiveRecord::Base.send(:include, Recaptcha::Verify)
