class DriverHistoriesController < ApplicationController
  load_and_authorize_resource :driver
  load_and_authorize_resource :driver_history, through: :driver
  
  respond_to :html, :js

  # GET /driver_histories/new
  def new
    prep_edit
  end

  # GET /driver_histories/1/edit
  def edit
    prep_edit
  end

  # POST /driver_histories
  def create
    if @driver_history.save
      respond_to do |format|
        format.html { redirect_to @driver, notice: 'Driver history was successfully created.' }
        format.js
      end
    else
      prep_edit
      render :new
    end
  end

  # PATCH/PUT /driver_histories/1
  def update
    if @driver_history.update(driver_history_params)
      respond_to do |format|
        format.html { redirect_to @driver, notice: 'Driver history was successfully updated.' }
        format.js
      end
    else
      prep_edit
      render :edit
    end
  end

  # DELETE /driver_histories/1
  def destroy
    @driver_history.destroy
    respond_to do |format|
      format.html { redirect_to @driver, notice: 'Driver history was successfully destroyed.' }
      format.js
    end
  end

  private

  def prep_edit
    @driver_history.document_associations.build
  end

  def driver_history_params
    params.require(:driver_history).permit(:event, :notes, :event_date, document_associations_attributes: [:id, :document_id, :_destroy])
  end
end
