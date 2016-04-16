class RegistrationsController < Devise::RegistrationsController

  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :odin_username, :odin_password, :odin_active, :ld_username, :ld_password, :ld_active)
  end

  def account_update_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :odin_username, :odin_password, :odin_active, :ld_username, :ld_password, :ld_active, :current_password)
  end
end