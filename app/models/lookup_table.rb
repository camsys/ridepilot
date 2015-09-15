class LookupTable < ActiveRecord::Base  
  validates_presence_of :name, :caption, :value_column_name
  validates_uniqueness_of :name

  def values(provider_id = nil)
    if is_provider_specific
      model.where(provider_id: provider_id).order(value_column_name)
    else
      model.all.order(value_column_name)
    end
  end

  def model
    (model_name || name.classify).constantize
  end

  def find_by_value(value, provider_id = nil)
    if is_provider_specific
      model.where("#{value_column_name}": value, provider_id: provider_id).first
    else
      model.find_by("#{value_column_name}": value)
    end
  end

  def add_value(value, provider_id = nil)
    if add_value_allowed
      if is_provider_specific
        model.create("#{value_column_name}": value, provider_id: provider_id) rescue nil 
      else
        model.create("#{value_column_name}": value) rescue nil 
      end
    end
  end

  def update_value(model_id, new_value)
    item = model.find_by_id(model_id)
    item.update("#{value_column_name}": new_value) if item && edit_value_allowed
    item
  end

  def destroy_value(model_id)
    item = model.find_by_id(model_id)
    item.destroy if item && delete_value_allowed

    item
  end
end
