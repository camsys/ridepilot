require "rails_helper"

RSpec.describe VehicleMaintenanceEventsController, type: :controller do
  login_admin_as_current_user
  
  describe "nested on vehicles" do
    before do
      @vehicle = create :vehicle, provider: @current_user.current_provider
    end

    it_behaves_like "a controller that accepts nested attributes for a document association" do
      before do
        @owner = @vehicle
      end
    end

    # This should return the minimal set of attributes required to create a 
    # valid VehicleMaintenanceEvent. As you add validations to
    # VehicleMaintenanceEvent, be sure to adjust the attributes here as well.
    let(:valid_attributes) { 
      attributes_for(:vehicle_maintenance_event)
    }

    let(:invalid_attributes) { 
      attributes_for(:vehicle_maintenance_event, services_performed: nil, service_date: nil)
    }

    describe "GET #new" do
      it "assigns a new vehicle_maintenance_event as @vehicle_maintenance_event" do
        get :new, {vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle_maintenance_event)).to be_a_new(VehicleMaintenanceEvent)
      end

      it "assigns the vehicle as @vehicle" do
        get :new, {vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle)).to eq(@vehicle)
      end

      it "sets @vehicle as the parent object on @vehicle_maintenance_event" do
        get :new, {vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle_maintenance_event).vehicle).to eq(@vehicle)
      end
    end

    describe "GET #edit" do
      it "assigns the requested vehicle_maintenance_event as @vehicle_maintenance_event" do
        vehicle_maintenance_event = create :vehicle_maintenance_event, vehicle: @vehicle
        get :edit, {:id => vehicle_maintenance_event.to_param, vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle_maintenance_event)).to eq(vehicle_maintenance_event)
      end

      it "assigns the vehicle as @vehicle" do
        vehicle_maintenance_event = create :vehicle_maintenance_event, vehicle: @vehicle
        get :edit, {:id => vehicle_maintenance_event.to_param, vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle)).to eq(@vehicle)
      end

      it "sets @vehicle as the parent object on @vehicle_maintenance_event" do
        vehicle_maintenance_event = create :vehicle_maintenance_event, vehicle: @vehicle
        get :edit, {:id => vehicle_maintenance_event.to_param, vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle_maintenance_event).vehicle).to eq(@vehicle)
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new vehicleCompliance" do
          expect {
            post :create, {:vehicle_maintenance_event => valid_attributes, vehicle_id: @vehicle.to_param}
          }.to change(VehicleMaintenanceEvent, :count).by(1)
        end

        it "assigns a newly created vehicle_maintenance_event as @vehicle_maintenance_event" do
          post :create, {:vehicle_maintenance_event => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_maintenance_event)).to be_a(VehicleMaintenanceEvent)
          expect(assigns(:vehicle_maintenance_event)).to be_persisted
        end

        it "sets @vehicle as the parent object on the new vehicle_maintenance_event" do
          post :create, {:vehicle_maintenance_event => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_maintenance_event).vehicle).to eq(@vehicle)
        end

        it "redirects back to the vehicle" do
          post :create, {:vehicle_maintenance_event => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to redirect_to(@vehicle)
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved vehicle_maintenance_event as @vehicle_maintenance_event" do
          skip("Nothing is required, and the model has no validations")
          post :create, {:vehicle_maintenance_event => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_maintenance_event)).to be_a_new(VehicleMaintenanceEvent)
        end

        it "re-renders the 'new' template" do
          skip("Nothing is required, and the model has no validations")
          post :create, {:vehicle_maintenance_event => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to render_template("new")
        end
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) {{
          odometer: "5432.1",
        }}

        it "updates the requested vehicle_maintenance_event" do
          vehicle_maintenance_event = create :vehicle_maintenance_event, vehicle: @vehicle
          put :update, {:id => vehicle_maintenance_event.to_param, :vehicle_maintenance_event => new_attributes, vehicle_id: @vehicle.to_param}
          vehicle_maintenance_event.reload
          expect(vehicle_maintenance_event.odometer).to eq(5432.1)
        end

        it "assigns the requested vehicle_maintenance_event as @vehicle_maintenance_event" do
          vehicle_maintenance_event = create :vehicle_maintenance_event, vehicle: @vehicle
          put :update, {:id => vehicle_maintenance_event.to_param, :vehicle_maintenance_event => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_maintenance_event)).to eq(vehicle_maintenance_event)
        end

        it "redirects back to the vehicle" do
          vehicle_maintenance_event = create :vehicle_maintenance_event, vehicle: @vehicle
          put :update, {:id => vehicle_maintenance_event.to_param, :vehicle_maintenance_event => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to redirect_to(@vehicle)
        end
      end

      context "with invalid params" do
        it "assigns the vehicle_maintenance_event as @vehicle_maintenance_event" do
          skip("Nothing is required, and the model has no validations")
          vehicle_maintenance_event = create :vehicle_maintenance_event, vehicle: @vehicle
          put :update, {:id => vehicle_maintenance_event.to_param, :vehicle_maintenance_event => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_maintenance_event)).to eq(vehicle_maintenance_event)
        end

        it "re-renders the 'edit' template" do
          skip("Nothing is required, and the model has no validations")
          vehicle_maintenance_event = create :vehicle_maintenance_event, vehicle: @vehicle
          put :update, {:id => vehicle_maintenance_event.to_param, :vehicle_maintenance_event => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested vehicle_maintenance_event" do
        vehicle_maintenance_event = create :vehicle_maintenance_event, vehicle: @vehicle
        expect {
          delete :destroy, {:id => vehicle_maintenance_event.to_param, vehicle_id: @vehicle.to_param}
        }.to change(VehicleMaintenanceEvent, :count).by(-1)
      end

      it "redirects back to the vehicle" do
        vehicle_maintenance_event = create :vehicle_maintenance_event, vehicle: @vehicle
        delete :destroy, {:id => vehicle_maintenance_event.to_param, vehicle_id: @vehicle.to_param}
        expect(response).to redirect_to(@vehicle)
      end
    end
  end
end
