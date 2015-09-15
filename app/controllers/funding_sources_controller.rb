class FundingSourcesController < ApplicationController
  load_and_authorize_resource

  def index; end

  def show
    redirect_to :action=>:edit
  end

  def new
    @funding_source = FundingSource.new
    @providers = Provider.all
    @checked_providers = []
  end

  def create
    if not params["provider"]
      flash.now[:alert] = "New funding sources must be associated with at least one provider"
      @providers = Provider.all
      @checked_providers = []
      render :action=>:new
      return
    end

    if @funding_source.save
      new_provider_ids = params["provider"]
      for id in new_provider_ids
        FundingSourceVisibility.create(:provider_id=>id, :funding_source_id=>@funding_source.id)
      end
      redirect_to(@funding_source, :notice => 'Funding source was successfully created.')
    else
      @providers = Provider.all
      render :action=>:new
    end
  end

  def edit
    @providers = Provider.all
    @checked_providers = @funding_source.providers
  end

  def update
    if @funding_source.update_attributes(funding_source_params)
      #now, handle changes to the provider list
      new_visibilities        = Provider.where(id: Array(params["provider"])).pluck(:id)
      current_visibilities    = @funding_source.funding_source_visibilities.pluck(:provider_id).uniq
      visibilities_to_create  = new_visibilities - current_visibilities
      visibilities_to_destroy = current_visibilities - (new_visibilities & current_visibilities)      

      @funding_source.funding_source_visibilities.destroy(@funding_source.funding_source_visibilities.where(:provider_id => visibilities_to_destroy))

      visibilities_to_create.each do |provider_id|
        @funding_source.funding_source_visibilities.create(:provider_id => provider_id)
      end

      redirect_to(@funding_source, :notice => 'Funding source was successfully created.')
    else
      @providers = Provider.all
      @checked_providers = @funding_source.providers
      render :action=>:edit
    end
  end
  
  private
  
  def funding_source_params
    params.require(:funding_source).permit(:name)
  end

end
