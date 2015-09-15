class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :apply_application_settings
  before_filter :do_not_track
  before_filter :authenticate_user!
  before_filter :get_providers
  before_filter :set_locale
  before_filter :set_cache_buster_for_xhr
  
  rescue_from CanCan::AccessDenied do |exception|
    render :file => "#{Rails.root}/public/403.html", :status => 403
  end

  def get_providers
    if !current_user
      return
    end

    @provider_map = []
    if current_user.super_admin?
      @provider_map = Provider.all.collect {|provider| [ provider.name, provider.id ] }
    else
      for role in current_user.roles
        @provider_map << [role.provider.name, role.provider_id]
      end
    end
    @provider_map.sort!{|a, b| a[0] <=> b[0] }
  end

  def test_exception_notification
    raise 'Testing, 1 2 3.'
  end

  private
  
  def apply_application_settings
    ApplicationSetting.apply!
  end
  
  def current_provider
    current_user.current_provider
  end

  def default_url_options(options={}) # This overrides/extends
    { locale: I18n.locale }
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def current_provider_id
    current_provider.try(:id)
  end

  def do_not_track
    # Devise is supposed to recognize this header, I thought. Unfortunately,
    # I'm having to check it manually.
    # TODO is this still true?
    if request.headers['devise.skip_trackable']
      request.env['devise.skip_trackable'] = true
    end
  end

  # Prevent AJAX requests/redirects from being cached
  def set_cache_buster_for_xhr
    if request.xhr?
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end
  end
end
