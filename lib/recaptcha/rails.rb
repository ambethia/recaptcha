require 'recaptcha'

ActionView::Base.send(:include, Recaptcha::ClientHelper)
ActionController::Base.send(:include, Recaptcha::Verify)
ActiveRecord::Base.send(:include, Recaptcha::ActiveRecordVerify::InstanceMethods)

