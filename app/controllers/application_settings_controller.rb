class ApplicationSettingsController < ApplicationController
  authorize_resource
  
  def index
  end

  def edit
    @settings = ApplicationSetting.all
  end

  def update
    respond_to do |format|
      if ApplicationSetting.update_settings(application_setting_params)
        format.html { redirect_to application_settings_path, notice: 'Application settings were successfully updated.' }
        format.json { head :no_content }
      else
        @settings = ApplicationSetting.all.merge(params[:application_setting])
        format.html { render action: :edit }
        format.json { render json: ApplicationSetting.all, status: :unprocessable_entity }
      end
    end
  end

  private

  def application_setting_params
    params.require(:application_setting).permit!
  end
end
