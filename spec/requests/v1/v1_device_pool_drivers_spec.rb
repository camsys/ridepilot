require 'spec_helper'

describe "V1::device_pool_drivers" do
  
  describe "POST /v1/device_pool_drivers/:id.json" do
    context "when not using https" do
      attr_reader :device_pool_driver
      
      before do
        @device_pool_driver = create_device_pool_driver :driver => create_driver, :device_pool => create_device_pool        
      end
      
      it "raises routing error" do
        lambda {
          post v1_device_pool_driver_path(:id => device_pool_driver.id, :device_pool_driver => { :status => "XXX" }, :secure => false, :format => "json")        
        }.should raise_error(ActionController::RoutingError)        
      end
    end
    
    context "when valid status update" do
      attr_reader :device_pool_driver
      
      before do
        @device_pool_driver = create_device_pool_driver :driver => create_driver, :device_pool => create_device_pool
        
        post v1_device_pool_driver_path(:id => device_pool_driver.id, :secure => true, :format => "json")
      end
      
      it "returns 200" do
        response.status.should be(200)
      end
      
      it "returns device as json" do
        response.body.should == {:device_pool_driver => device_pool_driver.reload.as_mobile_json }.to_json
      end
    end
    
    context "when invalid status update" do
      attr_reader :device_pool_driver
      
      before do
        @device_pool_driver = create_device_pool_driver :driver => create_driver, :device_pool => create_device_pool
        
        post v1_device_pool_driver_path(:id => device_pool_driver.id, :device_pool_driver => { :status => "XXX" }, :secure => true, :format => "json")        
      end
      
      it "returns 400" do
        response.status.should be(400)
      end
      
      it "returns error as json" do
        json = JSON.parse(response.body)
        json.should include("error")
      end
    end
    
    context "when invalid device_pool_driver_id" do
      
      before do        
        post v1_device_pool_driver_path(:id => 0, :device_pool_driver => { :status => DevicePoolDriver::Statuses.first }, :secure => true, :format => "json")        
      end
      
      it "returns 404" do
        response.status.should be(404)
      end
      
      it "returns error as json" do
        json = JSON.parse(response.body)
        json.should include("error")
      end
    end
  end
end
