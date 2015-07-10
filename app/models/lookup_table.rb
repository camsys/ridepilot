class LookupTable < ActiveRecord::Base
  validates_presence_of :name, :caption, :value_column_name
  validates_uniqueness_of :name

  def values
    model.all.order(value_column_name).select(:id, "#{value_column_name} as value")
  end

  def model
    name.constantize
  end

  def find(value)
    model.find_by("#{value_column_name}": value)
  end

  def add_value(value)
    model.create("#{value_column_name}": value)
  end

  def update_value(old_value, new_value)
    item = find(old_value)
    item.update("#{value_column_name}": new_value) if item
    item
  end

  def destroy_value(value)
    item = find(value)
    item.destroy if item

    item
  end
end
