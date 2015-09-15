class VehicleWarrantiesController < ApplicationController
  load_and_authorize_resource :vehicle
  load_and_authorize_resource :vehicle_warranty, through: :vehicle
  
  respond_to :html, :js

  # GET /vehicle_warranties/new
  def new
    prep_edit
  end

  # GET /vehicle_warranties/1/edit
  def edit
    prep_edit
  end

  # POST /vehicle_warranties
  def create
    if @vehicle_warranty.save
      respond_to do |format|
        format.html { redirect_to @vehicle, notice: 'Vehicle warranty was successfully created.' }
        format.js
      end
    else
      prep_edit
      render :new
    end
  end

  # PATCH/PUT /vehicle_warranties/1
  def update
    if @vehicle_warranty.update(vehicle_warranty_params)
      respond_to do |format|
        format.html { redirect_to @vehicle, notice: 'Vehicle warranty was successfully updated.' }
        format.js
      end
    else
      prep_edit
      render :edit
    end
  end

  # DELETE /vehicle_warranties/1
  def destroy
    @vehicle_warranty.destroy
    respond_to do |format|
      format.html { redirect_to @vehicle, notice: 'Vehicle warranty was successfully destroyed.' }
      format.js
    end
  end

  private
  
  def prep_edit
    @vehicle_warranty.document_associations.build
  end

  def vehicle_warranty_params
    params.require(:vehicle_warranty).permit(:description, :notes, :expiration_date, document_associations_attributes: [:id, :document_id, :_destroy])
  end
end
