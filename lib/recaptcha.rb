require 'recaptcha/recaptcha'
ActionView::Base.send :include, Ambethia::ReCaptcha::Helper
ActionController::Base.send :include, Ambethia::ReCaptcha::Controller
