require "rails_helper"

RSpec.describe AddressesController, type: :controller do
  login_admin_as_current_user

  # This should return the minimal set of attributes required to create a valid
  # Address. As you add validations to Address, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    attributes_for(:address)
  }

  let(:invalid_attributes) {
    attributes_for(:address, :address => "")
  }

  describe "GET #edit" do
    it "assigns the requested address as @address" do
      address = create(:address, :provider => @current_user.current_provider)
      get :edit, {:id => address.to_param}
      expect(assigns(:address)).to eq(address)
    end
  end

  describe "POST #create" do
    let(:valid_create_attributes) {
      # Convert the params to a flat list of params because that's what the
      # controller expects
      params = {"prefix" => "pickup"}
      valid_attributes.each do |k,v|
        params["#{params["prefix"]}_#{k}"] = v
      end
      params
    }
  
    context "with valid params" do
      context "specifying an existing address" do
        it "does not create a new Address" do
          address = create(:address, :provider => @current_user.current_provider)
          expect {
            post :create, valid_create_attributes.merge({:address_id => address.id})
          }.to_not change(Address, :count)
        end

        it "updates the requested vehicle" do
          address = create(:address, :provider => @current_user.current_provider, :address => "Foobar")
          expect {
            post :create, valid_create_attributes.merge({:address_id => address.id, :pickup_address => "Barfoo"})
          }.to change { address.reload.address }.from("Foobar").to("Barfoo")
        end

        it "responds with JSON" do
          address = create(:address, :provider => @current_user.current_provider)
          post :create, valid_create_attributes.merge({:address_id => address.id})
          expect(response.content_type).to eq("application/json")
        end

        it "includes the address attributes in the json response" do
          address = create(:address, :provider => @current_user.current_provider)
          post :create, valid_create_attributes.merge({:address_id => address.id})
          json = JSON.parse(response.body)
          expect(json["id"]).to be_a(Integer)
          expect(json["id"]).to eq(address.id)
        end
      end 
    
      context "without specifying an existing new address" do
        it "creates a new Address" do
          expect {
            post :create, valid_create_attributes
          }.to change(Address, :count).by(1)
        end

        it "responds with JSON" do
          post :create, valid_create_attributes
          expect(response.content_type).to eq("application/json")
        end

        it "includes the address attributes in the json response" do
          post :create, valid_create_attributes
          json = JSON.parse(response.body)
          expect(json["id"]).to be_a(Integer)
          expect(json["id"]).to eq(Address.last.id)
        end

        it "includes the address type in the json response" do
          post :create, valid_create_attributes
          json = JSON.parse(response.body)
          expect(json["prefix"]).to eq("pickup")
        end
      end
    end

    context "with invalid params" do
      let(:invalid_create_attributes) {
        valid_create_attributes.merge({"pickup_address" => ""})
      }

      it "responds with JSON" do
        post :create, invalid_create_attributes
        expect(response.content_type).to eq("application/json")
      end

      it "includes validation errors in the json response" do
        post :create, invalid_create_attributes
        json = JSON.parse(response.body)
        expect(json["address"]).to be_a(Array)
        expect(json["address"].first).to include("is too short")
      end

      it "includes the address type in the json response" do
        post :create, invalid_create_attributes
        json = JSON.parse(response.body)
        expect(json["prefix"]).to eq("pickup")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          :name => "Name",
          :building_name => "Building",
          :address => "Address",
          :city => "City",
          :state => "ST",
          :zip => "12345",
          :in_district => false,
          :the_geom => "",
          :phone_number => "555-5555",
          :inactive => false,
          :trip_purpose => create(:trip_purpose, name: "Purpose") ,
        }
      }

      it "updates the requested address" do
        address = Address.create! valid_attributes.merge({:provider_id => @current_user.current_provider.id, :address => "Foobar"})
        expect {
          put :update, {:id => address.to_param, :address => new_attributes}
        }.to change { address.reload.address }.from("Foobar").to("Address")
      end

      it "assigns the requested address as @address" do
        address = Address.create! valid_attributes.merge({:provider_id => @current_user.current_provider.id})
        put :update, {:id => address.to_param, :address => valid_attributes}
        expect(assigns(:address)).to eq(address)
      end

      it "redirects to the provider of the address" do
        address = Address.create! valid_attributes.merge({:provider_id => @current_user.current_provider.id})
        put :update, {:id => address.to_param, :address => valid_attributes}
        expect(response).to redirect_to(address.provider)
      end
    end

    context "with invalid params" do
      it "assigns the address as @address" do
        address = Address.create! valid_attributes.merge({:provider_id => @current_user.current_provider.id})
        put :update, {:id => address.to_param, :address => invalid_attributes}
        expect(assigns(:address)).to eq(address)
      end

      it "re-renders the 'edit' template" do
        address = Address.create! valid_attributes.merge({:provider_id => @current_user.current_provider.id})
        put :update, {:id => address.to_param, :address => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    context "when the address has trips associated with it" do
      before(:each) do
        @address = create(:address, :provider => @current_user.current_provider)
        @trip = create(:trip, :provider => @current_user.current_provider, :pickup_address => @address)
      end
    
      context "when a replacement address has been specified" do
        before(:each) do
          @replacement_address = Address.create! valid_attributes.merge({:provider_id => @current_user.current_provider.id})
        end
        
        it "destroys the requested address" do
          expect {
            delete :destroy, {:id => @address.to_param, :address_id => @replacement_address.id}
          }.to change(Address, :count).by(-1)
        end

        it "associates the trips with the replacement address" do
          expect {
            delete :destroy, {:id => @address.to_param, :address_id => @replacement_address.id}
          }.to change{ @trip.reload.pickup_address_id }.from(@address.id).to(@replacement_address.id)
        end

        it "redirects to the provider of the replacement address" do
          address = Address.create! valid_attributes.merge({:provider_id => @current_user.current_provider.id})
          delete :destroy, {:id => address.to_param, :address_id => @replacement_address.id}
          expect(response).to redirect_to(@replacement_address.provider)
        end        
      end
      
      context "when no replacement address has been specified" do
        it "does not destroy the requested address" do
          expect {
            delete :destroy, {:id => @address.to_param}
          }.to_not change(Address, :count)
        end

        it "redirects to the edit address page" do
          delete :destroy, {:id => @address.to_param}
          expect(response).to redirect_to(edit_address_path(@address))
        end        
      end
    end
    
    context "when no trips are associated with the address" do
      it "destroys the requested address" do
        address = Address.create! valid_attributes.merge({:provider_id => @current_user.current_provider.id})
        expect {
          delete :destroy, {:id => address.to_param}
        }.to change(Address, :count).by(-1)
      end

      it "redirects to the current user's provider" do
        address = Address.create! valid_attributes.merge({:provider_id => @current_user.current_provider.id})
        delete :destroy, {:id => address.to_param}
        expect(response).to redirect_to(@current_user.current_provider)
      end
    end
  end

  describe "GET #autocomplete" do
    # Sticking to high-level testing of this action since there's otherwise a 
    # lot of setup involved.
    
    let(:autocomplete_terms) {
      {
        :term => "foooo"
      }
    }

    it "responds with JSON" do
      post :autocomplete, autocomplete_terms
      expect(response.content_type).to eq("application/json")
    end

    it "include matching address info in the json response" do
      address = create(:address, :provider => @current_user.current_provider, :name => "foooo")
      post :autocomplete, autocomplete_terms
      json = JSON.parse(response.body)
      expect(json).to be_a(Array)
      expect(json.first["id"]).to be_a(Integer)
      expect(json.first["id"]).to eq(address.id)
    end

    it "include a new address in the json response if no other matches are found" do
      post :autocomplete, autocomplete_terms
      json = JSON.parse(response.body)
      expect(json).to be_a(Array)
      expect(json.first["id"]).to be_a(Integer)
      expect(json.first["id"]).to eq(0)
    end
  end

  describe "GET #search" do
    let(:search_terms) {
      {
        :name => "foooo",
        :provider_id => @current_user.current_provider.id,
        :format => "json"
      }
    }
    
    it "assigns the search term as @term" do
      get :search, search_terms
      expect(assigns(:term)).to eq("foooo")
    end
    
    it "assigns the requested provider as @provider" do
      get :search, search_terms
      expect(assigns(:provider)).to eq(@current_user.current_provider)
    end
        
    it "assigns the matching addresses as @addresses" do
      address_1 = create(:address, :provider => @current_user.current_provider, :name => "foooo")
      address_2 = create(:address, :provider => @current_user.current_provider, :building_name => "foooo")
      address_3 = create(:address, :provider => @current_user.current_provider, :address => "foooo")
      address_4 = create(:address, :provider => @current_user.current_provider)
      address_5 = create(:address)
      get :search, search_terms
      expect(assigns(:addresses)).to include(address_1)
      expect(assigns(:addresses)).to include(address_2)
      expect(assigns(:addresses)).to include(address_3)
      expect(assigns(:addresses)).to_not include(address_4)
      expect(assigns(:addresses)).to_not include(address_5)
    end

    it "responds with JSON" do
      get :search, search_terms
      expect(response.content_type).to eq("application/json")
    end
  end
end
