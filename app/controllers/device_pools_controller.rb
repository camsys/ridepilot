class DevicePoolsController < ApplicationController
  load_and_authorize_resource
  
  def new; end
  
  def create
    @device_pool.provider = current_provider
    @device_pool.color    = @device_pool.color.gsub(/#/, "")
    
    if @device_pool.save
      flash.now[:notice] = "Device pool created"
      redirect_to provider_path(current_provider)
    else
      render :action=>:new
    end
  end
  
  def edit; end
  
  def update
    params[:device_pool][:color] = params[:device_pool][:color].gsub(/#/, "")
    
    if @device_pool.update_attributes(device_pool_params)
      flash.now[:notice] = "Device pool updated"
      redirect_to provider_path(current_provider)
    else
      render :action=>:edit
    end
  end
  
  def destroy
    @device_pool.destroy
    respond_to do |format|
      format.html {
        flash.now[:notice] = "Device pool deleted"
        redirect_to provider_path(current_provider)        
      }
      format.js { 
        render :json => { :device_pool => @device_pool.as_json }
      }
    end
  end
  
  private
  
  def device_pool_params
    params.require(:device_pool).permit(:name, :color)
  end
end
