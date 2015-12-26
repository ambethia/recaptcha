class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if verify_recaptcha(model: @user, message: 'Error in passing CAPTCHA.') && @user.save
      redirect_to users_path, notice: "Saved"
    else
      render 'edit'
    end
  end
end
