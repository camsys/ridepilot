require 'rails_helper'

RSpec.describe VehicleMaintenanceCompliancesController, type: :controller do
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
    # valid VehicleMaintenanceCompliance. As you add validations to
    # VehicleMaintenanceCompliance, be sure to adjust the attributes here as
    # well.
    let(:valid_attributes) {{
      event: "My Maintenance Compliance Event",
      due_type: "date",
      due_date: Date.current.to_s,
    }}

    let(:invalid_attributes) {{
      event: nil,
      due_type: nil,
    }}

    describe "GET #new" do
      it "assigns a new vehicle_maintenance_compliance as @vehicle_maintenance_compliance" do
        get :new, {vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle_maintenance_compliance)).to be_a_new(VehicleMaintenanceCompliance)
      end

      it "assigns the vehicle as @vehicle" do
        get :new, {vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle)).to eq(@vehicle)
      end

      it "sets @vehicle as the parent object on @vehicle_maintenance_compliance" do
        get :new, {vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle_maintenance_compliance).vehicle).to eq(@vehicle)
      end
    end

    describe "GET #edit" do
      it "assigns the requested vehicle_maintenance_compliance as @vehicle_maintenance_compliance" do
        vehicle_maintenance_compliance = create :vehicle_maintenance_compliance, vehicle: @vehicle
        get :edit, {:id => vehicle_maintenance_compliance.to_param, vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle_maintenance_compliance)).to eq(vehicle_maintenance_compliance)
      end

      it "assigns the vehicle as @vehicle" do
        vehicle_maintenance_compliance = create :vehicle_maintenance_compliance, vehicle: @vehicle
        get :edit, {:id => vehicle_maintenance_compliance.to_param, vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle)).to eq(@vehicle)
      end

      it "sets @vehicle as the parent object on @vehicle_maintenance_compliance" do
        vehicle_maintenance_compliance = create :vehicle_maintenance_compliance, vehicle: @vehicle
        get :edit, {:id => vehicle_maintenance_compliance.to_param, vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle_maintenance_compliance).vehicle).to eq(@vehicle)
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new VehicleMaintenanceCompliance" do
          expect {
            post :create, {:vehicle_maintenance_compliance => valid_attributes, vehicle_id: @vehicle.to_param}
          }.to change(VehicleMaintenanceCompliance, :count).by(1)
        end

        it "assigns a newly created vehicle_maintenance_compliance as @vehicle_maintenance_compliance" do
          post :create, {:vehicle_maintenance_compliance => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_maintenance_compliance)).to be_a(VehicleMaintenanceCompliance)
          expect(assigns(:vehicle_maintenance_compliance)).to be_persisted
        end

        it "sets @vehicle as the parent object on the new vehicle_maintenance_compliance" do
          post :create, {:vehicle_maintenance_compliance => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_maintenance_compliance).vehicle).to eq(@vehicle)
        end

        it "redirects back to the vehicle" do
          post :create, {:vehicle_maintenance_compliance => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to redirect_to(@vehicle)
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved vehicle_maintenance_compliance as @vehicle_maintenance_compliance" do
          post :create, {:vehicle_maintenance_compliance => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_maintenance_compliance)).to be_a_new(VehicleMaintenanceCompliance)
        end

        it "re-renders the 'new' template" do
          post :create, {:vehicle_maintenance_compliance => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to render_template("new")
        end
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) {{
          event: "My New Maintenance Compliance Event",
        }}

        it "updates the requested vehicle_maintenance_compliance" do
          vehicle_maintenance_compliance = create :vehicle_maintenance_compliance, vehicle: @vehicle
          put :update, {:id => vehicle_maintenance_compliance.to_param, :vehicle_maintenance_compliance => new_attributes, vehicle_id: @vehicle.to_param}
          vehicle_maintenance_compliance.reload
          expect(vehicle_maintenance_compliance.event).to eq("My New Maintenance Compliance Event")
        end

        it "assigns the requested vehicle_maintenance_compliance as @vehicle_maintenance_compliance" do
          vehicle_maintenance_compliance = create :vehicle_maintenance_compliance, vehicle: @vehicle
          put :update, {:id => vehicle_maintenance_compliance.to_param, :vehicle_maintenance_compliance => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_maintenance_compliance)).to eq(vehicle_maintenance_compliance)
        end

        it "redirects back to the vehicle" do
          vehicle_maintenance_compliance = create :vehicle_maintenance_compliance, vehicle: @vehicle
          put :update, {:id => vehicle_maintenance_compliance.to_param, :vehicle_maintenance_compliance => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to redirect_to(@vehicle)
        end
      end

      context "with invalid params" do
        it "assigns the vehicle_maintenance_compliance as @vehicle_maintenance_compliance" do
          vehicle_maintenance_compliance = create :vehicle_maintenance_compliance, vehicle: @vehicle
          put :update, {:id => vehicle_maintenance_compliance.to_param, :vehicle_maintenance_compliance => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_maintenance_compliance)).to eq(vehicle_maintenance_compliance)
        end

        it "re-renders the 'edit' template" do
          vehicle_maintenance_compliance = create :vehicle_maintenance_compliance, vehicle: @vehicle
          put :update, {:id => vehicle_maintenance_compliance.to_param, :vehicle_maintenance_compliance => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested vehicle_maintenance_compliance" do
        vehicle_maintenance_compliance = create :vehicle_maintenance_compliance, vehicle: @vehicle
        expect {
          delete :destroy, {:id => vehicle_maintenance_compliance.to_param, vehicle_id: @vehicle.to_param}
        }.to change(VehicleMaintenanceCompliance, :count).by(-1)
      end

      it "redirects back to the vehicle" do
        vehicle_maintenance_compliance = create :vehicle_maintenance_compliance, vehicle: @vehicle
        delete :destroy, {:id => vehicle_maintenance_compliance.to_param, vehicle_id: @vehicle.to_param}
        expect(response).to redirect_to(@vehicle)
      end
    end
  end
end
