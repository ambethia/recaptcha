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
end


