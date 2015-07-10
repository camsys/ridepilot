class Address < ActiveRecord::Base
  belongs_to :provider

  belongs_to :trip_purpose
  delegate :name, to: :trip_purpose, prefix: :trip_purpose, allow_nil: true
  
  has_many :trips_from, :class_name => "Trip", :foreign_key => :pickup_address_id
  has_many :trips_to, :class_name => "Trip", :foreign_key => :dropoff_address_id

  normalize_attribute :name, :with=> [:squish, :titleize]
  normalize_attribute :building_name, :with=> [:squish, :titleize]
  normalize_attribute :address, :with=> [:squish, :titleize]
  normalize_attribute :city, :with=> [:squish, :titleize]

  validates :address, :length => { :minimum => 5 }
  validates :city,    :length => { :minimum => 2 }
  validates :state,   :length => { :is => 2 }
  validates :zip,     :length => { :is => 5, :if => lambda { |a| a.zip.present? } }
  
  before_validation :compute_in_trimet_district

  has_paper_trail
  
  NewAddressOption = { :label => "New Address", :id => 0 }

  scope :for_provider,    -> (provider) { where(:provider_id => provider.id) }
  scope :search_for_term, -> (term) { where("LOWER(name) LIKE '%' || :term || '%' OR LOWER(building_name) LIKE '%' || :term || '%' OR LOWER(address) LIKE '%' || :term || '%'",{:term => term}) }

  def trips
    trips_from + trips_to
  end
  
  def replace_with!(address_id)
    return false unless address_id.present? && self.class.exists?(address_id)
    
    self.trips_from.each do |trip|
      trip.update_attribute :pickup_address_id, address_id
    end
    
    self.trips_to.each do |trip|
      trip.update_attribute :dropoff_address_id, address_id
    end
    
    self.destroy
    self.class.find address_id
  end
  
  def compute_in_trimet_district
    if the_geom and in_district.nil?
      in_district = Region.count(:conditions => ["name='TriMet' and st_contains(the_geom, ?)", the_geom]) > 0
    end 
  end

  def latitude
    if the_geom
      return the_geom.x
    else
      return nil
    end
  end

  def longitude
    if the_geom
      return the_geom.y
    else
      return nil
    end
  end

  def latitude=(x)
    the_geom.x = x
  end

  def longitude=(y)
    the_geom.y = y
  end

  def text
    if building_name.to_s.size > 0 and name.to_s.size > 0
      first_line = "%s - %s\n" % [name, building_name]
    elsif building_name.to_s.size > 0
      first_line = building_name + "\n"
    elsif name.to_s.size > 0
      first_line = name + "\n"
    else
      first_line = ''
    end

    return ("%s%s\n%s, %s  %s" % [first_line, address, city, state, zip]).strip

  end

  def json
    {
      :label => text, 
      :id => id, 
      :name => name,
      :building_name => building_name,
      :address => address,
      :city => city,
      :state => state,
      :zip => zip,
      :in_district => in_district,
      :phone_number => phone_number,
      :lat => latitude,
      :lon => longitude,
      :default_trip_purpose => trip_purpose_name
    }
  end

end
