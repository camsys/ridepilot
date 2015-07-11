require "rails_helper"

RSpec.describe CabTripsController, type: :controller do
  login_admin_as_current_user

  describe "GET #index" do
    it "should be successful" do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET #edit_multiple" do
    before(:each) do
      @drivers   = create_list(:driver,   5, :provider => @current_user.current_provider)
      @vehicles  = create_list(:vehicle,  5, :provider => @current_user.current_provider)
      @cab_trips = create_list(:cab_trip, 5, :pickup_time => Time.zone.now, :provider => @current_user.current_provider)
    end
    
    it "assigns all currently accessible drivers as @drivers" do
      get :edit_multiple
      expect(assigns(:drivers)).to match_array(@drivers)
    end
    
    it "assigns all currently accessible vehicles as @vehicles" do
      get :edit_multiple
      expect(assigns(:vehicles)).to match_array(@vehicles)
    end
    
    it "assigns all currently accessible cab trips as @cab_trips" do
      get :edit_multiple, {:start => Date.today.in_time_zone.to_i}
      expect(assigns(:cab_trips)).to include(@cab_trips[0])
      expect(assigns(:cab_trips)).to include(@cab_trips[1])
      expect(assigns(:cab_trips)).to include(@cab_trips[2])
      expect(assigns(:cab_trips)).to include(@cab_trips[3])
      expect(assigns(:cab_trips)).to include(@cab_trips[4])
    end
    
    it "should be successful" do
      get :edit_multiple
      expect(response).to be_success
    end
  end
  
  describe "PUT #update_multiple" do
    before do
      @start_date = Date.today.beginning_of_week.in_time_zone
      @end_date = Date.today.end_of_week.in_time_zone
      @t1 = create(:cab_trip, provider: @current_user.current_provider, pickup_time: Time.zone.now, attendant_count: 0)
      @t2 = create(:cab_trip, provider: @current_user.current_provider, pickup_time: Time.zone.now, attendant_count: 0)
      cab_trip_params = {
        @t1.id => {
          attendant_count: 1
        },
        @t2.id => {
          attendant_count: 2
        }
      }
      put 'update_multiple', cab_trips: cab_trip_params
    end
    
    it "should be successful" do
      expect(response).to redirect_to(cab_trips_path(start: @start_date.to_i, end: @end_date.to_i))
    end
    
    it "should update the submitted trips" do
      expect(Trip.find(@t1.id).attendant_count).to eq(1)
      expect(Trip.find(@t2.id).attendant_count).to eq(2)
    end
  end
end