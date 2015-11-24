class CaptchaController < ApplicationController
  def index
  end

  def create
    if verify_recaptcha
      render text: 'YES'
    else
      render text: 'NO'
    end
  end
end
