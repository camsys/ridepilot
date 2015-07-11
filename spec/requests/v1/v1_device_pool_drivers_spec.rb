require "rails_helper"

RSpec.describe "V1::device_pool_drivers" do
  
  describe "POST /device_pool_drivers.json" do
    context "when not using https" do
      attr_reader :device_pool_driver, :user
      
      before do
        @user = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => user
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user)
      end
      
      it "raises routing error" do
        expect {
          post v1_device_pool_drivers_url(:format => "json", :protocol => "http", :host => 'localhost'), { :user => { :email => user.email, :password => "password#1" } }
        }.to raise_error(ActionController::RoutingError)        
      end
    end
    
    context "when not passing user params" do
      attr_reader :device_pool_driver, :user
      
      before do
        @user = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => user
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user)
          
        post v1_device_pool_drivers_url(:format => "json", :protocol => "https", :host => 'localhost')
      end

      it "returns 401" do
        expect(response.status).to be(401)
      end

      it "returns error" do
        expect(response.body).to match("No user found")
      end
    end
    
    context "when passing bad user params" do
      attr_reader :device_pool_driver, :user
      
      before do
        @user = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => user
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user)
          
        post v1_device_pool_drivers_url(:format => "json", :protocol => "https", :host => 'localhost'), { :user => { :email => user.email, :password => "wrong" } }
      end

      it "returns 401" do
        expect(response.status).to be(401)
      end

      it "returns error" do
        expect(response.body).to match("No user found")
      end
    end
    
    context "when user has no device_pool_driver" do
      attr_reader :device_pool_driver, :user, :current_user

      before do
        @current_user       = create :user, :password => "password#1", :password_confirmation => "password#1"
        @user               = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => current_user
        create :role, :level => 0, :user => user
        
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user)

        post v1_device_pool_drivers_url(:format => "json", :protocol => "https", :host => 'localhost'), { :user => { :email => current_user.email, :password => "password#1" } }
      end

      it "returns 401" do
        expect(response.status).to be(401)
      end

      it "returns error" do
        expect(response.body).to match("User does not have access to this resource")
      end
    end
    
    context "when passing capitalized email" do
      attr_reader :device_pool_driver, :user

      before do
        @user               = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => user
        
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user)

        post v1_device_pool_drivers_url(:format => "json", :protocol => "https", :host => 'localhost'), { :user => { :email => user.email.upcase, :password => "password#1" } }
      end

      it "returns 200" do
        expect(response.status).to be(200)
      end
    end
    
    context "when user has device_pool_driver" do
      attr_reader :device_pool_driver, :user

      before do
        @user               = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => user
        
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user)

        post v1_device_pool_drivers_url(:format => "json", :protocol => "https", :host => 'localhost'), { :user => { :email => user.email, :password => "password#1" } }
      end

      it "returns 200" do
        expect(response.status).to be(200)
      end

      it "returns resource_url" do
        expect(response.body).to match v1_device_pool_driver_url(:id => device_pool_driver.id, :format => "json", protocol: "https", :host => 'localhost')
      end
    end
  end
  
  describe "POST /v1/device_pool_drivers/:id.json" do
    context "when not using https" do
      attr_reader :device_pool_driver, :user
      
      before do
        @user = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => user
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user)
      end
      
      it "raises routing error" do
        expect {
          post v1_device_pool_driver_url(device_pool_driver.id, :host => "localhost", :format => "json", :protocol => "http"), { :user => { :email => user.email, :password => "password#1" }, :device_pool_driver => { :status => "XXX" } }
        }.to raise_error(ActionController::RoutingError)        
      end
    end
    
    context "when not passing user params" do
      attr_reader :device_pool_driver
      
      before do
        @device_pool_driver = create :device_pool_driver
        
        post v1_device_pool_driver_url(device_pool_driver.id, :host => "localhost", :format => "json", :protocol => "https")
      end
      
      it "returns 401" do
        expect(response.status).to be(401)
      end
      
      it "returns error" do
        expect(response.body).to match("No user found")
      end
    end
    
    context "when passing bad user params" do
      attr_reader :device_pool_driver, :user
      
      before do
        @user               = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => user
        
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user)
                
        post v1_device_pool_driver_url(device_pool_driver.id, :host => "localhost", :format => "json", :protocol => "https"), { :user => { :email => user.email, :password => "wrong" } }
      end
      
      it "returns 401" do
        expect(response.status).to be(401)
      end
      
      it "returns error" do
        expect(response.body).to match("No user found")
      end
    end
    
    context "when passing params that do not map to the driver for this resource" do
      attr_reader :device_pool_driver, :user, :current_user

      before do
        @current_user       = create :user, :password => "password#1", :password_confirmation => "password#1"
        @user               = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => current_user
        create :role, :level => 0, :user => user
        
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user)

        post v1_device_pool_driver_url(device_pool_driver.id, :host => "localhost", :format => "json", :protocol => "https"), { :user => { :email => current_user.email, :password => "password#1" } }
      end

      it "returns 401" do
        expect(response.status).to be(401)
      end

      it "returns error" do
        expect(response.body).to match("User does not have access to this resource")
      end
    end
    
    context "when valid status update" do
      attr_reader :device_pool_driver, :user
      
      before do
        @user = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => user
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user)
        
        post v1_device_pool_driver_url(device_pool_driver.id, :host => "localhost", :format => "json", :protocol => "https"), { :user => { :email => user.email, :password => "password#1" }, :device_pool_driver => { :status => "break", :lat => "45.5", :lng => "-122.6" } }
      end
      
      it "returns 200" do
        expect(response.status).to be(200)
      end
      
      it "returns device as json" do
        expect(response.body).to eq({:device_pool_driver => device_pool_driver.reload.as_mobile_json }.to_json)
      end
    end
    
    context "when lacking coordinates" do
      attr_reader :device_pool_driver, :user
      
      before do
        @user = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => user
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user), :lat => 45.5, :lng => -122.6
        
        post v1_device_pool_driver_url(device_pool_driver.id, :host => "localhost", :format => "json", :protocol => "https"), { :user => { :email => user.email, :password => "password#1" }, :device_pool_driver => { :status => "break", :lat => "", :lng => "" } }
      end
      
      it "returns 200" do
        expect(response.status).to be(200)
      end
      
      it "does not update the coordinates" do
        device_pool_driver.reload
        expect([device_pool_driver.lat, device_pool_driver.lng]).to eq([45.5, -122.6])
      end
    end
    
    context "when invalid status update" do
      attr_reader :device_pool_driver, :user
      
      before do
        @user = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => user
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user)
                
        post v1_device_pool_driver_url(device_pool_driver.id, :host => "localhost", :format => "json", :protocol => "https"), { :user => { :email => user.email, :password => "password#1" }, :device_pool_driver => { :status => "XXX" } }
      end
      
      it "returns 400" do
        expect(response.status).to be(400)
      end
      
      it "returns error as json" do
        json = JSON.parse(response.body)
        expect(json).to include("error")
      end
    end
    
    context "when invalid device_pool_driver_id" do
      attr_reader :device_pool_driver, :user

      before do
        @user = create :user, :password => "password#1", :password_confirmation => "password#1"
        create :role, :level => 0, :user => user
        @device_pool_driver = create :device_pool_driver, :driver => create(:driver, :user => @user)
        
        post v1_device_pool_driver_url(0, :format => "json", :protocol => "https", :host => 'localhost'), { :user => { :email => user.email, :password => "password#1" }, :device_pool_driver => { :status => DevicePoolDriver::Statuses.first } }
      end
      
      it "returns 404" do
        expect(response.status).to be(404)
      end
      
      it "returns error as json" do
        json = JSON.parse(response.body)
        expect(json).to include("error")
      end
    end
  end
end
