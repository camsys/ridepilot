require 'new_user_mailer'

class UsersController < ApplicationController
  def new_user
    authorize! :edit, current_user.current_provider
    @user = User.new
    @errors = []
  end

  def create_user
    authorize! :edit, current_user.current_provider
    
    #this user might already be a member of the site, but not of this
    #provider, in which case we ought to just set up the role
    @user = User.find_by_email(params[:user][:email])
    @role = Role.new
    new_password = nil
    new_user = false
    record_valid = false
    User.transaction do
      begin
        if not @user
          @user = User.new(create_user_params)
          @user.password = User.generate_password
          raw, enc = Devise.token_generator.generate(User, :reset_password_token)
          @user.reset_password_token = enc
          @user.reset_password_sent_at = Time.now.utc
          @user.current_provider = current_provider
          @user.save!
          new_user = true
        end

        @role.user = @user
        @role.provider = current_provider
        @role.level = params[:role][:level]
        @role.save!

        record_valid = true
      rescue => e
        Rails.logger.info(e)
        raise ActiveRecord::Rollback
      end
    end

    if record_valid
      # NewUserMailer doesn't server the purpose by design
      #NewUserMailer.new_user_email(@user, new_password).deliver if new_user

      # send password reset instructions instead
      @user.send_reset_password_instructions  if new_user

      flash[:notice] = "%s has been added and the instructions has been emailed" % @user.email
      redirect_to provider_path(current_provider)
    else
      user_errors = @user.valid? ? {} : @user.errors.messages
      role_errors = @role.valid? ? {} : @role.errors.messages
      @errors = user_errors.merge(role_errors)
      render :action => :new_user
    end
  end
  
  def show_change_password
    @user = current_user
  end

  def change_password
    if current_user.update_password(change_password_params)
      sign_in(current_user, :bypass => true)
      flash[:notice] = "Password changed"
      redirect_to '/'
    else
      flash.now[:alert] = "Error updating password"
      render :action=>:show_change_password
    end
  end

  def change_provider
    provider = Provider.find(params[:provider_id])
    if can? :read, provider
      current_user.current_provider = provider
      current_user.save!
    end
    redirect_to params[:come_from]
  end

  def check_session
    last_request_at = session['warden.user.user.session']['last_request_at']
    timeout_time = last_request_at + Rails.configuration.devise.timeout_in.to_i
    timeout_in = timeout_time - Time.current.to_i
    render :json => {
      'last_request_at' => last_request_at,
      'timeout_in' => timeout_in,
    }
  end

  def touch_session
    render :text => 'OK'
  end

  private
  
  def create_user_params
    params.require(:user).permit(:email)
  end
  
  def change_password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
