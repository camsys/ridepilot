["Scooter", "Wheelchair", "Wheelchair - Oversized", "Wheelchair - Can Transfer", "Unknown", "Ambulatory"].each do |name|
  Mobility.find_or_create_by!(:name => name)
end