require 'rails_helper'

RSpec.describe LookupTable, type: :model do
  it "has a valid lookup table object" do 
    expect(build(:lookup_table)).to be_valid
  end

  describe "validations" do

    it "is invalid without name" do 
      expect(build(:lookup_table, name: nil)).to be_invalid
    end

    it "is invalid with duplicated name" do 
      create(:lookup_table)
      expect(build(:lookup_table)).to be_invalid
    end

    it "is valid with unique name" do 
      create(:lookup_table)
      expect(build(:lookup_table, name: 'Unique Name')).to be_valid
    end
  end

  describe "queries" do

    it "returns all values of a model" do 
      sample_purpose_1 = create(:trip_purpose, name: 'Sample Purpose 1')
      sample_purpose_2 = create(:trip_purpose, name: 'Sample Purpose 2')
      table = create(:lookup_table)

      expect(table.values).to eq([sample_purpose_1, sample_purpose_2])
    end

    it "finds the valid value of lookup table" do 
      sample_purpose = create(:trip_purpose, name: 'Sample Purpose')
      table = create(:lookup_table)

      expect(table.find_by_value('Sample Purpose')).to eq(sample_purpose)
    end
  end

  it "has a valid correspondent model" do 
    table = create(:lookup_table, name: 'TripPurpose')
    expect(table.model).to eq(TripPurpose)
  end

  describe "has valid permissions to edit values" do 

    context "add value" do
      it "adds value with add_value_allowed permission" do
        table = create(:lookup_table)
        new_item = table.add_value('Sample Purpose')
        expect(TripPurpose.first).to eq(TripPurpose.find_by_name('Sample Purpose'))
      end
      it "cannot add value without add_value_allowed permission" do
        table = create(:lookup_table, add_value_allowed: false)
        new_item = table.add_value('Sample Purpose')
        expect(TripPurpose.first).to eq(nil)
      end
    end

    context "edit value" do
      it "edits value with edit_value_allowed permission" do 
        table = create(:lookup_table)
        purpose = create(:trip_purpose, name: 'Sample Purpose')
        table.update_value(purpose.id, 'New Purpose')
        expect(TripPurpose.first).to eq(TripPurpose.find_by_name('New Purpose'))
      end
      it "cannot edit value without edit_value_allowed permission" do 
        table = create(:lookup_table, edit_value_allowed: false)
        purpose= create(:trip_purpose, name: 'Sample Purpose')
        table.update_value(purpose.id, 'New Purpose')
        expect(TripPurpose.first).to eq(TripPurpose.find_by_name('Sample Purpose'))
      end
    end

    context "delete value" do
      it "delets value with delete_value_allowed permission" do 
        table = create(:lookup_table)
        purpose = create(:trip_purpose, name: 'Sample Purpose')
        table.destroy_value(purpose.id)
        expect(TripPurpose.first).to eq(nil)
      end 
      it "cannot delete value without add_value_allowed permission" do
        table = create(:lookup_table, delete_value_allowed: false)
        purpose= create(:trip_purpose, name: 'Sample Purpose')
        table.destroy_value(purpose.id)
        expect(TripPurpose.first).to eq(TripPurpose.find_by_name('Sample Purpose'))
      end
    end
  end

end
