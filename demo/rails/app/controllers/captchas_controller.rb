class CaptchasController < ApplicationController
  def index
  end

  def create
    if verify_recaptcha
      render plain: 'YES'
    else
      render plain: 'NO'
    end
  end
end
