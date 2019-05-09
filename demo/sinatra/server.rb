require 'bundler/setup'
require 'sinatra'
require 'recaptcha'

# these will only work on localhost ... make your own at https://www.google.com/recaptcha
Recaptcha.configure do |config|
  config.site_key  = '6Le7oRETAAAAAETt105rjswZ15EuVJiF7BxPROkY'
  config.secret_key = '6Le7oRETAAAAAL5a8yOmEdmDi3b2pH7mq5iH1bYK'
end

include Recaptcha::Adapters::ControllerMethods
include Recaptcha::Adapters::ViewMethods

get '/' do
  <<-HTML
    <form action="/verify">
      #{recaptcha_tags}
      <input type="submit"/>
    </form>
  HTML
end

get '/verify' do
  if verify_recaptcha
    'YES!'
  else
    'NO!'
  end
end
