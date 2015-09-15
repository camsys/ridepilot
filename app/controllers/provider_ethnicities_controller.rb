class ProviderEthnicitiesController < ApplicationController
  load_and_authorize_resource

  def index
    redirect_to provider_path(current_provider)
  end

  def show; end

  def new; end

  def edit; end

  def create
    @provider_ethnicity.provider = current_provider
    if @provider_ethnicity.save
      flash.now[:notice] = "Ethnicity created"
      redirect_to provider_path(current_provider)
    else
      render :action => :new
    end
  end

  def update
    @provider_ethnicity.provider = current_provider
    if @provider_ethnicity.update_attributes(provider_ethnicity_params)
      flash.now[:notice] = "Ethnicity updated"
      redirect_to provider_path(current_provider)
    else
      render :action => :edit
    end 
  end

  def destroy
    @provider_ethnicity.destroy
    redirect_to provider_path(current_provider)
  end
  
  private
  
  def provider_ethnicity_params
    params.require(:provider_ethnicity).permit(:name)
  end
end
