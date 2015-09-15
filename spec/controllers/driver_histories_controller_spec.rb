require 'rails_helper'

RSpec.describe DriverHistoriesController, type: :controller do
  login_admin_as_current_user

  describe "nested on drivers" do
    before do
      @driver = create :driver, provider: @current_user.current_provider
    end
    
    it_behaves_like "a controller that accepts nested attributes for a document association" do
      before do
        @owner = @driver
      end
    end

    # This should return the minimal set of attributes required to create a 
    # valid DriverHistory. As you add validations to DriverHistory, be sure to
    # adjust the attributes here as well.
    let(:valid_attributes) {{
      event: "My History Event",
      event_date: Date.current.to_s
    }}

    let(:invalid_attributes) {{
      event: nil,
      event_date: nil
    }}

    describe "GET #new" do
      it "assigns a new driver_history as @driver_history" do
        get :new, {driver_id: @driver.to_param}
        expect(assigns(:driver_history)).to be_a_new(DriverHistory)
      end

      it "assigns the driver as @driver" do
        get :new, {driver_id: @driver.to_param}
        expect(assigns(:driver)).to eq(@driver)
      end

      it "sets @driver as the parent object on @driver_history" do
        get :new, {driver_id: @driver.to_param}
        expect(assigns(:driver_history).driver).to eq(@driver)
      end
    end

    describe "GET #edit" do
      it "assigns the requested driver_history as @driver_history" do
        driver_history = create :driver_history, driver: @driver
        get :edit, {:id => driver_history.to_param, driver_id: @driver.to_param}
        expect(assigns(:driver_history)).to eq(driver_history)
      end

      it "assigns the driver as @driver" do
        driver_history = create :driver_history, driver: @driver
        get :edit, {:id => driver_history.to_param, driver_id: @driver.to_param}
        expect(assigns(:driver)).to eq(@driver)
      end

      it "sets @driver as the parent object on @driver_history" do
        driver_history = create :driver_history, driver: @driver
        get :edit, {:id => driver_history.to_param, driver_id: @driver.to_param}
        expect(assigns(:driver_history).driver).to eq(@driver)
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new DriverHistory" do
          expect {
            post :create, {:driver_history => valid_attributes, driver_id: @driver.to_param}
          }.to change(DriverHistory, :count).by(1)
        end

        it "assigns a newly created driver_history as @driver_history" do
          post :create, {:driver_history => valid_attributes, driver_id: @driver.to_param}
          expect(assigns(:driver_history)).to be_a(DriverHistory)
          expect(assigns(:driver_history)).to be_persisted
        end

        it "sets @driver as the parent object on the new driver_history" do
          post :create, {:driver_history => valid_attributes, driver_id: @driver.to_param}
          expect(assigns(:driver_history).driver).to eq(@driver)
        end

        it "redirects back to the driver" do
          post :create, {:driver_history => valid_attributes, driver_id: @driver.to_param}
          expect(response).to redirect_to(@driver)
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved driver_history as @driver_history" do
          post :create, {:driver_history => invalid_attributes, driver_id: @driver.to_param}
          expect(assigns(:driver_history)).to be_a_new(DriverHistory)
        end

        it "re-renders the 'new' template" do
          post :create, {:driver_history => invalid_attributes, driver_id: @driver.to_param}
          expect(response).to render_template("new")
        end
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) {{
          event: "My New History Event",
        }}

        it "updates the requested driver_history" do
          driver_history = create :driver_history, driver: @driver
          put :update, {:id => driver_history.to_param, :driver_history => new_attributes, driver_id: @driver.to_param}
          driver_history.reload
          expect(driver_history.event).to eq("My New History Event")
        end

        it "assigns the requested driver_history as @driver_history" do
          driver_history = create :driver_history, driver: @driver
          put :update, {:id => driver_history.to_param, :driver_history => valid_attributes, driver_id: @driver.to_param}
          expect(assigns(:driver_history)).to eq(driver_history)
        end

        it "redirects back to the driver" do
          driver_history = create :driver_history, driver: @driver
          put :update, {:id => driver_history.to_param, :driver_history => valid_attributes, driver_id: @driver.to_param}
          expect(response).to redirect_to(@driver)
        end
      end

      context "with invalid params" do
        it "assigns the driver_history as @driver_history" do
          driver_history = create :driver_history, driver: @driver
          put :update, {:id => driver_history.to_param, :driver_history => invalid_attributes, driver_id: @driver.to_param}
          expect(assigns(:driver_history)).to eq(driver_history)
        end

        it "re-renders the 'edit' template" do
          driver_history = create :driver_history, driver: @driver
          put :update, {:id => driver_history.to_param, :driver_history => invalid_attributes, driver_id: @driver.to_param}
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested driver_history" do
        driver_history = create :driver_history, driver: @driver
        expect {
          delete :destroy, {:id => driver_history.to_param, driver_id: @driver.to_param}
        }.to change(DriverHistory, :count).by(-1)
      end

      it "redirects back to the driver" do
        driver_history = create :driver_history, driver: @driver
        delete :destroy, {:id => driver_history.to_param, driver_id: @driver.to_param}
        expect(response).to redirect_to(@driver)
      end
    end
  end
end
