RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # config.gem "recaptcha", :lib => "recaptcha/rails"
  config.time_zone = 'UTC'

  ActionController::Base.session = {
    :key         => '_recaptcha-example-rails_session',
    :secret      => '7af66b0b811942ee51e08ce297a1a2743ecf3717086aeac2f49f8bd48cbbe7bc78c78a964000cd14932ed2aa3aede630cd4bc937dece02f008c95dc47347b73f'
  }
end

