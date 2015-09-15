require 'rails_helper'

RSpec.describe VehicleWarrantiesController, type: :controller do
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
    # valid VehicleWarranty. As you add validations to VehicleWarranty, be sure
    # to adjust the attributes here as well.
    let(:valid_attributes) {{
      description: "My Warranty",
      expiration_date: Date.current.to_s,
    }}

    let(:invalid_attributes) {{
      description: nil,
      expiration_date: nil
    }}

    describe "GET #new" do
      it "assigns a new vehicle_warranty as @vehicle_warranty" do
        get :new, {vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle_warranty)).to be_a_new(VehicleWarranty)
      end

      it "assigns the vehicle as @vehicle" do
        get :new, {vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle)).to eq(@vehicle)
      end

      it "sets @vehicle as the parent object on @vehicle_warranty" do
        get :new, {vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle_warranty).vehicle).to eq(@vehicle)
      end
    end

    describe "GET #edit" do
      it "assigns the requested vehicle_warranty as @vehicle_warranty" do
        vehicle_warranty = create :vehicle_warranty, vehicle: @vehicle
        get :edit, {:id => vehicle_warranty.to_param, vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle_warranty)).to eq(vehicle_warranty)
      end

      it "assigns the vehicle as @vehicle" do
        vehicle_warranty = create :vehicle_warranty, vehicle: @vehicle
        get :edit, {:id => vehicle_warranty.to_param, vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle)).to eq(@vehicle)
      end

      it "sets @vehicle as the parent object on @vehicle_warranty" do
        vehicle_warranty = create :vehicle_warranty, vehicle: @vehicle
        get :edit, {:id => vehicle_warranty.to_param, vehicle_id: @vehicle.to_param}
        expect(assigns(:vehicle_warranty).vehicle).to eq(@vehicle)
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new VehicleWarranty" do
          expect {
            post :create, {:vehicle_warranty => valid_attributes, vehicle_id: @vehicle.to_param}
          }.to change(VehicleWarranty, :count).by(1)
        end

        it "assigns a newly created vehicle_warranty as @vehicle_warranty" do
          post :create, {:vehicle_warranty => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_warranty)).to be_a(VehicleWarranty)
          expect(assigns(:vehicle_warranty)).to be_persisted
        end

        it "sets @vehicle as the parent object on the new vehicle_warranty" do
          post :create, {:vehicle_warranty => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_warranty).vehicle).to eq(@vehicle)
        end

        it "redirects back to the vehicle" do
          post :create, {:vehicle_warranty => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to redirect_to(@vehicle)
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved vehicle_warranty as @vehicle_warranty" do
          post :create, {:vehicle_warranty => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_warranty)).to be_a_new(VehicleWarranty)
        end

        it "re-renders the 'new' template" do
          post :create, {:vehicle_warranty => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to render_template("new")
        end
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) {{
          description: "My New Warranty"
        }}

        it "updates the requested vehicle_warranty" do
          vehicle_warranty = create :vehicle_warranty, vehicle: @vehicle
          put :update, {:id => vehicle_warranty.to_param, :vehicle_warranty => new_attributes, vehicle_id: @vehicle.to_param}
          vehicle_warranty.reload
          expect(vehicle_warranty.description).to eq("My New Warranty")
        end

        it "assigns the requested vehicle_warranty as @vehicle_warranty" do
          vehicle_warranty = create :vehicle_warranty, vehicle: @vehicle
          put :update, {:id => vehicle_warranty.to_param, :vehicle_warranty => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_warranty)).to eq(vehicle_warranty)
        end

        it "redirects back to the vehicle" do
          vehicle_warranty = create :vehicle_warranty, vehicle: @vehicle
          put :update, {:id => vehicle_warranty.to_param, :vehicle_warranty => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to redirect_to(@vehicle)
        end
      end

      context "with invalid params" do
        it "assigns the vehicle_warranty as @vehicle_warranty" do
          vehicle_warranty = create :vehicle_warranty, vehicle: @vehicle
          put :update, {:id => vehicle_warranty.to_param, :vehicle_warranty => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:vehicle_warranty)).to eq(vehicle_warranty)
        end

        it "re-renders the 'edit' template" do
          vehicle_warranty = create :vehicle_warranty, vehicle: @vehicle
          put :update, {:id => vehicle_warranty.to_param, :vehicle_warranty => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested vehicle_warranty" do
        vehicle_warranty = create :vehicle_warranty, vehicle: @vehicle
        expect {
          delete :destroy, {:id => vehicle_warranty.to_param, vehicle_id: @vehicle.to_param}
        }.to change(VehicleWarranty, :count).by(-1)
      end

      it "redirects back to the vehicle" do
        vehicle_warranty = create :vehicle_warranty, vehicle: @vehicle
        delete :destroy, {:id => vehicle_warranty.to_param, vehicle_id: @vehicle.to_param}
        expect(response).to redirect_to(@vehicle)
      end
    end
  end
end
