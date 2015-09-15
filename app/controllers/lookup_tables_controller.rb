class LookupTablesController < ApplicationController
  load_and_authorize_resource
  before_action :set_lookup_tables, only: [:index, :show]
  before_action :set_lookup_table, except: [:index]

  def index
    @first_lookup_table = @lookup_tables.first
    redirect_to lookup_table_path(@first_lookup_table) if @first_lookup_table.present?
  end

  def show
  end

  def add_value
    @item = @lookup_table.add_value(params[:value], current_provider_id)
    redirect_to_show_page
  end

  def update_value
    @item = @lookup_table.update_value(params[:model_id], params[:value])
    redirect_to_show_page
  end

  def destroy_value
    @item = @lookup_table.destroy_value(params[:model_id])
    redirect_to_show_page
  end

  private

  def set_lookup_tables
    @lookup_tables = LookupTable.order(:caption)
  end

  def set_lookup_table
    @lookup_table = LookupTable.find params[:id]
  end

  def redirect_to_show_page
    if @item && !@item.errors.empty?
      flash.now[:alert] = TranslationEngine.translate_text(:operation_failed) + ": "
      flash.now[:alert] += @item.errors.full_messages.join(';')
    end
    redirect_to lookup_table_path(@lookup_table)
  end
end
