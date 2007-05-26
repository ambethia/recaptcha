require 'recaptcha.rb'
ActionView::Base.send :include, Ambethia::ReCaptcha::Helper
ActionController::Base.send :include, Ambethia::ReCaptcha::Controller