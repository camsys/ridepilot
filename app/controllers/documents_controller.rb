class DocumentsController < ApplicationController
  # Try to load any polymorphic associations
  load_resource :driver
  load_resource :vehicle
  
  # Load documents through their associated parent
  load_and_authorize_resource :document, through: [:driver, :vehicle]
    
  before_filter :set_parent
  before_filter :authorize_parent

  respond_to :html, :js

  # GET /documents/new
  def new
  end

  # GET /documents/1/edit
  def edit
  end

  # POST /documents
  def create
    if @document.save
      respond_to do |format|
        format.html { redirect_to @parent, notice: 'Document was successfully created.' }
        format.js
      end
    else
      render :new
    end
  end

  # PATCH/PUT /documents/1
  def update
    if @document.update(document_params)
      respond_to do |format|
        format.html { redirect_to @parent, notice: 'Document was successfully updated.' }
        format.js
      end
    else
      render :edit
    end
  end

  # DELETE /documents/1
  def destroy
    @document.destroy
    respond_to do |format|
      format.html { redirect_to @parent, notice: 'Document was successfully destroyed.' }
      format.js
    end
  end

  private
  
  def document_params
    params.require(:document).permit(:description, :document)
  end

  def set_parent
    @parent = @driver || @vehicle
  end

  def authorize_parent
    authorize! :manage, @parent
  end
end
