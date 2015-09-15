class DevicePool < ActiveRecord::Base
  acts_as_paranoid # soft delete
  
  belongs_to  :provider
  has_many    :device_pool_drivers, :dependent => :destroy
  has_many    :drivers, :through => :device_pool_drivers
  
  validates :name, :presence => true
  validates :color, :presence => true
  
  validates :color, :length => { :is => 6, :if => lambda { self.color.present? } }
  
  def as_json
    {
      :data     => "#{name} <span class='color' style='background-color: ##{color}'> </span>",
      :metadata => { :id => id },
      :attr     => { :rel => "device_pool", "data-color" => color, "data-id" => id },
      :children => device_pool_drivers.sort{|a,b| a.name <=> b.name}.map( &:as_tree_json )
    }
  end
  
  class Tree < Hash
    
    def initialize(pools)
      pools.sort!{|a,b| a.provider.name <=> b.provider.name}
      for pool in pools do
        self[pool.provider.name] = ( self[pool.provider.name] || [] ) << pool
      end
    end
    
    def as_json
      self.map do |provider_name, device_pools|
        {
          :data     => provider_name,
          :attr     => { :rel => "provider" },
          :children => self[provider_name].sort{|a,b| a.name <=> b.name}.map( &:as_json )
        }
      end
    end
  end
end
