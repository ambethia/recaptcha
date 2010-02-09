class ExampleController < ApplicationController
  def index
  end

  def verify
    if verify_recaptcha
      flash[:message] = "Verify Success"
    else
      flash[:message] = "Verify Failure"
    end
    render :index
  end
end
