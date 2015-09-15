class DriverCompliancesController < ApplicationController
  load_and_authorize_resource :driver
  load_and_authorize_resource :driver_compliance, through: :driver
  
  respond_to :html, :js

  # GET /driver_compliances/new
  def new
    prep_edit
  end

  # GET /driver_compliances/1/edit
  def edit
    prep_edit
  end

  # POST /driver_compliances
  def create
    if @driver_compliance.save
      respond_to do |format|
        format.html { redirect_to @driver, notice: 'Driver compliance was successfully created.' }
        format.js
      end
    else
      prep_edit
      render :new
    end
  end

  # PATCH/PUT /driver_compliances/1
  def update
    if @driver_compliance.update(driver_compliance_params)
      respond_to do |format|
        format.html { redirect_to @driver, notice: 'Driver compliance was successfully updated.' }
        format.js
      end
    else
      prep_edit
      render :edit
    end
  end

  # DELETE /driver_compliances/1
  def destroy
    @driver_compliance.destroy
    respond_to do |format|
      format.html { redirect_to @driver, notice: 'Driver compliance was successfully destroyed.' }
      format.js
    end
  end

  private
  
  def prep_edit
    @driver_compliance.document_associations.build
  end

  def driver_compliance_params
    params.require(:driver_compliance).permit(:event, :notes, :due_date, :compliance_date, document_associations_attributes: [:id, :document_id, :_destroy])
  end
end
