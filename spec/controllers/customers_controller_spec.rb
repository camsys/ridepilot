require 'rails_helper'

RSpec.describe CustomersController, type: :controller do
  login_admin_as_current_user

  # This should return the minimal set of attributes required to create a valid
  # Customer. As you add validations to Customer, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    attributes_for(:customer)
  }

  let(:invalid_attributes) {
    attributes_for(:customer, :first_name => "")
  }

  describe "GET #index" do
    it "assigns all active customers as @customers" do
      customer_1 = create(:customer, :provider => @current_user.current_provider)
      customer_2 = create(:customer, :provider => @current_user.current_provider, :inactivated_date => Date.today)
      get :index, {}
      expect(assigns(:customers)).to include(customer_1)
      expect(assigns(:customers)).to_not include(customer_2)
    end
  end

  describe "GET #all" do
    it "assigns *all* customers as @customers" do
      customer_1 = create(:customer, :provider => @current_user.current_provider)
      customer_2 = create(:customer, :provider => @current_user.current_provider, :inactivated_date => Date.today)
      get :all, {}
      expect(assigns(:customers)).to include(customer_1)
      expect(assigns(:customers)).to include(customer_2)
    end
  end
  
  describe "GET #show" do
    it "assigns the requested customer as @customer" do
      customer = create(:customer, :provider => @current_user.current_provider)
      get :show, {:id => customer.to_param}
      expect(assigns(:customer)).to eq(customer)
    end
  end

  describe "GET #new" do
    it "assigns a new customer as @customer" do
      get :new, {}
      expect(assigns(:customer)).to be_a_new(Customer)
    end
  end

  describe "GET #edit" do
    it "assigns the requested customer as @customer" do
      customer = create(:customer, :provider => @current_user.current_provider)
      get :edit, {:id => customer.to_param}
      expect(assigns(:customer)).to eq(customer)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Customer" do
        expect {
          post :create, {:customer => valid_attributes}
        }.to change(Customer, :count).by(1)
      end

      it "assigns a newly created customer as @customer" do
        post :create, {:customer => valid_attributes}
        expect(assigns(:customer)).to be_a(Customer)
        expect(assigns(:customer)).to be_persisted
      end

      it "should tell me if a duplicate customer exists" do
        customer = create(:customer, email: "abc@def.ghi", provider: @current_user.current_provider)
        put :create, {customer: customer.dup.attributes}
        expect(flash.keys).to include("alert")
        expect(flash["alert"]).to include('There is already a customer with a similar name or the same email address')
        expect(assigns(:customer)).to_not be_persisted
        expect(response).to render_template("new")
      end

      it "redirects to the created customer" do
        skip 'somehow the outcome is not stable which caused the failure'
        post :create, {:customer => valid_attributes}
        expect(response).to redirect_to(Customer.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved customer as @customer" do
        post :create, {:customer => invalid_attributes}
        expect(assigns(:customer)).to be_a_new(Customer)
      end

      it "re-renders the 'new' template" do
        post :create, {:customer => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end
  
  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          :first_name => "MyString",
          :midle_initial => "MyString",
          :last_name => "MyString",
          :phone_number_1 => "MyString",
          :phone_number_2 => "MyString",
          :address_attributes => {
            :name => "Name",
            :building_name => "Building",
            :address => "Address",
            :city => "City",
            :state => "ST",
            :zip => "12345",
            :provider_id => @current_user.current_provider.id,
          },
          :email => "MyString",
          :activated_date => "2015-02-23 00:00:00",
          :inactivated_date => "2015-02-23 00:00:00",
          :inactivated_reason => "MyString",
          :birth_date => "2015-02-23 00:00:00",
          :mobility_id => create(:mobility).id,
          :mobility_notes => "MyText",
          :ethnicity => "MyString",
          :emergency_contact_notes => "MyText",
          :private_notes => "MyText",
          :public_notes => "MyText",
          :group => false,
          :medicaid_eligible => false,
          :prime_number => "MyString",
          :default_funding_source_id => create(:funding_source, :provider => @current_user.current_provider).id,
          :ada_eligible => false,
          :service_level_id => create(:service_level).id,
        }
      }

      it "updates the requested customer" do
        customer = create(:customer, :provider => @current_user.current_provider, :first_name => "Foo")
        expect {
          put :update, {:id => customer.to_param, :customer => new_attributes}
        }.to change{ customer.reload.first_name }.from("Foo").to("MyString")
      end

      it "assigns the requested customer as @customer" do
        customer = create(:customer, :provider => @current_user.current_provider)
        put :update, {:id => customer.to_param, :customer => valid_attributes}
        expect(assigns(:customer)).to eq(customer)
      end

      it "redirects to the customer" do
        customer = create(:customer, :provider => @current_user.current_provider)
        put :update, {:id => customer.to_param, :customer => valid_attributes}
        expect(response).to redirect_to(customer)
      end
    end

    context "with invalid params" do
      it "assigns the customer as @customer" do
        customer = create(:customer, :provider => @current_user.current_provider)
        put :update, {:id => customer.to_param, :customer => invalid_attributes}
        expect(assigns(:customer)).to eq(customer)
      end

      it "re-renders the 'edit' template" do
        customer = create(:customer, :provider => @current_user.current_provider)
        put :update, {:id => customer.to_param, :customer => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested customer" do
      customer = create(:customer, :provider => @current_user.current_provider)
      expect {
        delete :destroy, {:id => customer.to_param}
      }.to change(Customer, :count).by(-1)
    end

    it "redirects to the customers list" do
      customer = create(:customer, :provider => @current_user.current_provider)
      delete :destroy, {:id => customer.to_param}
      expect(response).to redirect_to(customers_url)
    end
  end

  describe "POST #inactivate" do
    it "inactivates the requested Customer" do
      customer = create(:customer, :provider => @current_user.current_provider)
      expect {
        post :inactivate, {:customer_id => customer.id, :customer => {:inactivated_reason => "because"}}
      }.to change{ customer.reload.inactivated_date.try(:in_time_zone).to_i }.from(0).to(Date.today.in_time_zone.to_i)
    end

    it "assigns the requested customer as @customer" do
      customer = create(:customer, :provider => @current_user.current_provider)
      post :inactivate, {:customer_id => customer.id, :customer => {:inactivated_reason => "because"}}
      expect(assigns(:customer)).to eq(customer)
    end

    it "redirects to the :index" do
      customer = create(:customer, :provider => @current_user.current_provider)
      post :inactivate, {:customer_id => customer.id, :customer => {:inactivated_reason => "because"}}
      expect(response).to redirect_to(customers_path)
    end
  end
  
  describe "GET #found" do
    it "redirects to :search when :customer_id is blank" do
      get :found, {:customer_id => "", :customer_name => "foooo"}
      expect(response).to redirect_to(search_customers_path(:term => "foooo"))
    end
    
    it "redirects to new_trip_path when :commit starts_with \"new trip\"" do
      get :found, {:customer_id => "1", :commit => "new trip"}
      expect(response).to redirect_to(new_trip_path(:customer_id => "1"))
    end
    
    it "otherwise redirects to the requested customer" do
      get :found, {:customer_id => "1", :commit => ""}
      expect(response).to redirect_to(customer_path("1"))
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
      get :autocomplete, autocomplete_terms
      expect(response.content_type).to eq("application/json")
    end

    it "include matching address info in the json response" do
      customer = create(:customer, :provider => @current_user.current_provider, :first_name => "foooo")
      get :autocomplete, autocomplete_terms
      json = JSON.parse(response.body)
      expect(json).to be_a(Array)
      expect(json.first["id"]).to be_a(Integer)
      expect(json.first["id"]).to eq(customer.id)
    end
  end

  describe "GET #search" do
    let(:search_terms) {
      {
        :term => "foooo"
      }
    }
    
    it "assigns the matching customers as @customers" do
      customer_1 = create(:customer, :provider => @current_user.current_provider, :first_name => "foooo")
      customer_2 = create(:customer, :provider => @current_user.current_provider, :last_name => "foooo")
      customer_3 = create(:customer, :provider => @current_user.current_provider)
      customer_4 = create(:customer, :first_name => "foooo")
      get :search, search_terms
      expect(assigns(:customers)).to include(customer_1)
      expect(assigns(:customers)).to include(customer_2)
      expect(assigns(:customers)).to_not include(customer_3)
      expect(assigns(:customers)).to_not include(customer_4)
    end

    it "renders the 'index' template" do
      get :search, search_terms
      expect(response).to render_template("index")
    end
  end
  
end
