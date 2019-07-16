class V3CaptchasController < ApplicationController
  def index
  end

  def create
    if verify_recaptcha(action: 'demo', minimum_score: 0.5)
      render plain: 'YES'
    else
      render plain: 'NO'
    end
  end

  def create_multi
    if verify_recaptcha(action: 'demo_a', minimum_score: 0.5) &&
       verify_recaptcha(action: 'demo_b', minimum_score: 0.5)
      render plain: 'YES'
    else
      render plain: 'NO'
    end
  end

  def create_with_v2_fallback
    success          = verify_recaptcha(action: 'login', minimum_score: 0.2, secret_key: ENV['RECAPTCHA_SECRET_KEY_V3'], **response_option)
    checkbox_success = verify_recaptcha unless success
    if success || checkbox_success
      render plain: 'Success'
    else
      if !success
        @show_checkbox_recaptcha = true
      end
      render 'index'
    end
  end

private

# This is only used to be able to simulate a failure. You wouldn't need this in a production app.
  def response_option
    if params[:commit] =~ /fail/i
      # Simulate a failure
      # Note that this doesn't work for v2 with the default testing key because it always returns
      # success for that key.
      response_option = {response: 'bogus'}
    else
      # Use the response token that was submitted
      response_option = {}
    end
  end

end

