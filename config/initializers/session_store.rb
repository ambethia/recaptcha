# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_recaptcha-example-rails_session',
  :secret      => '7af66b0b811942ee51e08ce297a1a2743ecf3717086aeac2f49f8bd48cbbe7bc78c78a964000cd14932ed2aa3aede630cd4bc937dece02f008c95dc47347b73f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
