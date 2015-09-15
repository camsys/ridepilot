require 'rails_helper'

RSpec.describe DocumentsController, type: :controller do
  login_admin_as_current_user

  # This should return the minimal set of attributes required to create a valid
  # Document. As you add validations to Document, be sure to adjust the 
  # attributes here as well.
  let(:valid_attributes) {{
    description: "My Description",
    document: Rack::Test::UploadedFile.new(Rails.root.join("spec", "samples", "image.png"), "image/png")
  }}

  let(:invalid_attributes) {{
    description: "",
    document: ""
  }}

  describe "nested on drivers" do
    before do
      @driver = create :driver, provider: @current_user.current_provider
    end
    
    describe "GET #new" do
      it "assigns a new document as @document" do
        get :new, {driver_id: @driver.to_param}
        expect(assigns(:document)).to be_a_new(Document)
      end

      it "assigns the driver as @parent" do
        get :new, {driver_id: @driver.to_param}
        expect(assigns(:parent)).to eq(@driver)
      end

      it "sets @driver as the documentable object on @document" do
        get :new, {driver_id: @driver.to_param}
        expect(assigns(:document).documentable).to eq(@driver)
      end
    end

    describe "GET #edit" do
      it "assigns the requested document as @document" do
        @document = create :document, documentable: @driver
        get :edit, {:id => @document.to_param, driver_id: @driver.to_param}
        expect(assigns(:document)).to eq(@document)
      end

      it "assigns the driver as @parent" do
        @document = create :document, documentable: @driver
        get :edit, {:id => @document.to_param, driver_id: @driver.to_param}
        expect(assigns(:parent)).to eq(@driver)
      end

      it "sets @driver as the documentable object on @document" do
        @document = create :document, documentable: @driver
        get :edit, {:id => @document.to_param, driver_id: @driver.to_param}
        expect(assigns(:document).documentable).to eq(@driver)
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new Document" do
          expect {
            post :create, {:document => valid_attributes, driver_id: @driver.to_param}
          }.to change(Document, :count).by(1)
        end

        it "assigns a newly created document as @document" do
          post :create, {:document => valid_attributes, driver_id: @driver.to_param}
          expect(assigns(:document)).to be_a(Document)
          expect(assigns(:document)).to be_persisted
        end

        it "sets @driver as the documentable object on the new document" do
          post :create, {:document => valid_attributes, driver_id: @driver.to_param}
          expect(assigns(:document).documentable).to eq(@driver)
        end

        it "redirects back to the driver" do
          post :create, {:document => valid_attributes, driver_id: @driver.to_param}
          expect(response).to redirect_to(@driver)
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved document as @document" do
          post :create, {:document => invalid_attributes, driver_id: @driver.to_param}
          expect(assigns(:document)).to be_a_new(Document)
        end

        it "re-renders the 'new' template" do
          post :create, {:document => invalid_attributes, driver_id: @driver.to_param}
          expect(response).to render_template("new")
        end
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) {{
          description: "My New Description"
        }}

        it "updates the requested document" do
          document = create :document, documentable: @driver
          put :update, {:id => document.to_param, :document => new_attributes, driver_id: @driver.to_param}
          document.reload
          expect(document.description).to eq("My New Description")
        end

        it "assigns the requested document as @document" do
          document = create :document, documentable: @driver
          put :update, {:id => document.to_param, :document => valid_attributes, driver_id: @driver.to_param}
          expect(assigns(:document)).to eq(document)
        end

        it "redirects back to the driver" do
          document = create :document, documentable: @driver
          put :update, {:id => document.to_param, :document => valid_attributes, driver_id: @driver.to_param}
          expect(response).to redirect_to(@driver)
        end
      end

      context "with invalid params" do
        it "assigns the document as @document" do
          document = create :document, documentable: @driver
          put :update, {:id => document.to_param, :document => invalid_attributes, driver_id: @driver.to_param}
          expect(assigns(:document)).to eq(document)
        end

        it "re-renders the 'edit' template" do
          document = create :document, documentable: @driver
          put :update, {:id => document.to_param, :document => invalid_attributes, driver_id: @driver.to_param}
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested document" do
        document = create :document, documentable: @driver
        expect {
          delete :destroy, {:id => document.to_param, driver_id: @driver.to_param}
        }.to change(Document, :count).by(-1)
      end

      it "redirects back to the driver" do
        document = create :document, documentable: @driver
        delete :destroy, {:id => document.to_param, driver_id: @driver.to_param}
        expect(response).to redirect_to(@driver)
      end
    end
  end

  describe "nested on vehicles" do
    before do
      @vehicle = create :vehicle, provider: @current_user.current_provider
    end

    describe "GET #new" do
      it "assigns a new document as @document" do
        get :new, {vehicle_id: @vehicle.to_param}
        expect(assigns(:document)).to be_a_new(Document)
      end

      it "assigns the vehicle as @parent" do
        get :new, {vehicle_id: @vehicle.to_param}
        expect(assigns(:parent)).to eq(@vehicle)
      end

      it "sets @vehicle as the documentable object on @document" do
        get :new, {vehicle_id: @vehicle.to_param}
        expect(assigns(:document).documentable).to eq(@vehicle)
      end
    end

    describe "GET #edit" do
      it "assigns the requested document as @document" do
        @document = create :document, documentable: @vehicle
        get :edit, {:id => @document.to_param, vehicle_id: @vehicle.to_param}
        expect(assigns(:document)).to eq(@document)
      end

      it "assigns the vehicle as @parent" do
        @document = create :document, documentable: @vehicle
        get :edit, {:id => @document.to_param, vehicle_id: @vehicle.to_param}
        expect(assigns(:parent)).to eq(@vehicle)
      end

      it "sets @vehicle as the documentable object on @document" do
        @document = create :document, documentable: @vehicle
        get :edit, {:id => @document.to_param, vehicle_id: @vehicle.to_param}
        expect(assigns(:document).documentable).to eq(@vehicle)
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new Document" do
          expect {
            post :create, {:document => valid_attributes, vehicle_id: @vehicle.to_param}
          }.to change(Document, :count).by(1)
        end

        it "assigns a newly created document as @document" do
          post :create, {:document => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:document)).to be_a(Document)
          expect(assigns(:document)).to be_persisted
        end

        it "sets @vehicle as the documentable object on the new document" do
          post :create, {:document => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:document).documentable).to eq(@vehicle)
        end

        it "redirects back to the vehicle" do
          post :create, {:document => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to redirect_to(@vehicle)
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved document as @document" do
          post :create, {:document => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:document)).to be_a_new(Document)
        end

        it "re-renders the 'new' template" do
          post :create, {:document => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to render_template("new")
        end
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) {{
          description: "My New Description"
        }}

        it "updates the requested document" do
          document = create :document, documentable: @vehicle
          put :update, {:id => document.to_param, :document => new_attributes, vehicle_id: @vehicle.to_param}
          document.reload
          expect(document.description).to eq("My New Description")
        end

        it "assigns the requested document as @document" do
          document = create :document, documentable: @vehicle
          put :update, {:id => document.to_param, :document => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:document)).to eq(document)
        end

        it "redirects back to the vehicle" do
          document = create :document, documentable: @vehicle
          put :update, {:id => document.to_param, :document => valid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to redirect_to(@vehicle)
        end
      end

      context "with invalid params" do
        it "assigns the document as @document" do
          document = create :document, documentable: @vehicle
          put :update, {:id => document.to_param, :document => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(assigns(:document)).to eq(document)
        end

        it "re-renders the 'edit' template" do
          document = create :document, documentable: @vehicle
          put :update, {:id => document.to_param, :document => invalid_attributes, vehicle_id: @vehicle.to_param}
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested document" do
        document = create :document, documentable: @vehicle
        expect {
          delete :destroy, {:id => document.to_param, vehicle_id: @vehicle.to_param}
        }.to change(Document, :count).by(-1)
      end

      it "redirects back to the vehicle" do
        document = create :document, documentable: @vehicle
        delete :destroy, {:id => document.to_param, vehicle_id: @vehicle.to_param}
        expect(response).to redirect_to(@vehicle)
      end
    end
  end
end
