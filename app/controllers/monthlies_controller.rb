class MonthliesController < ApplicationController
  load_and_authorize_resource
  before_filter :prep_edit

  def index
    @monthlies = @monthlies.order(:start_date)
  end

  def new; end

  def edit; end

  def update
    @monthly.update_attributes(monthly_params)
    if @monthly.save
      flash.now[:notice] = "Monthly report updated"
      redirect_to monthlies_path
    else
      render :edit
    end
  end

  def create
    @monthly.provider = current_provider
    if @monthly.save
      flash.now[:notice] = "Monthly report created"
      redirect_to monthlies_path
    else
      render :new
    end
  end
  
  private
  
  def prep_edit
    @funding_sources = FundingSource.by_provider(current_provider)
  end
  
  def monthly_params
    params.require(:monthly).permit(:start_date, :volunteer_escort_hours, :volunteer_admin_hours, :funding_source_id)
  end
end