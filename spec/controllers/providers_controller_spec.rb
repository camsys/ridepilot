require "rails_helper"

RSpec.describe ProvidersController, type: :controller do
  # This controller requires super_admin access
  login_super_admin_as_current_user

  # This should return the minimal set of attributes required to create a valid
  # Provider. As you add validations to Provider, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    # Only name is required, but since there's no :update action we'll use the
    # :create action to exercise the strong parameters
    attributes_for(:provider,
      :dispatch => false,
      :scheduling => false,
      :region_nw_corner => "",
      :region_se_corner => "",
      :viewport_center => "",
      :viewport_zoom => "",
      :allow_trip_entry_from_runs_page => false,
      :oaa3b_per_ride_reimbursement_rate => "9.99",
      :ride_connection_per_ride_reimbursement_rate => "9.99",
      :trimet_per_ride_reimbursement_rate => "9.99",
      :stf_van_per_ride_reimbursement_rate => "9.99",
      :stf_taxi_per_ride_administrative_fee => "9.99",
      :stf_taxi_per_ride_ambulatory_load_fee => "9.99",
      :stf_taxi_per_ride_wheelchair_load_fee => "9.99",
      :stf_taxi_per_mile_ambulatory_reimbursement_rate => "9.99",
      :stf_taxi_per_mile_wheelchair_reimbursement_rate => "9.99"
    )
  }

  let(:invalid_attributes) {
    attributes_for(:provider, :name => "")
  }

  describe "GET #index" do
    it "assigns all providers as @providers" do
      provider = create(:provider)
      get :index, {}
      expect(assigns(:providers)).to include(provider)
    end
  end

  describe "GET #show" do
    it "assigns the requested provider as @provider" do
      provider = create(:provider)
      get :show, {:id => provider.to_param}
      expect(assigns(:provider)).to eq(provider)
    end
  end

  describe "GET #new" do
    it "assigns a new provider as @provider" do
      get :new, {}
      expect(assigns(:provider)).to be_a_new(Provider)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Provider" do
        expect {
          post :create, {:provider => valid_attributes}
        }.to change(Provider, :count).by(1)
      end

      it "assigns a newly created provider as @provider" do
        post :create, {:provider => valid_attributes}
        expect(assigns(:provider)).to be_a(Provider)
        expect(assigns(:provider)).to be_persisted
      end

      it "redirects to the created provider" do
        post :create, {:provider => valid_attributes}
        expect(response).to redirect_to(Provider.last)
      end
    end

    context "with invalid params" do
      it "borks" do
        expect {
          post :create, {:provider => invalid_attributes}
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "POST #change_role" do
    it "updates the requested role" do
      role = create(:role, :provider => @current_user.current_provider, :level => 50)
      expect {
        post :change_role, {:provider_id => @current_user.current_provider.id, :role => {:id => role.id, :level => 100}}
      }.to change{ role.reload.level }.from(50).to(100)
    end

    it "redirects to the provider" do
      role = create(:role, :provider => @current_user.current_provider, :level => 50)
      post :change_role, {:provider_id => @current_user.current_provider.id, :role => {:id => role.id, :level => 100}}
      expect(response).to redirect_to(@current_user.current_provider)
    end
  end

  describe "POST #delete_role" do
    it "destroys the requested role" do
      role = create(:role, :provider => @current_user.current_provider)
      expect {
        post :delete_role, {:provider_id => @current_user.current_provider.id, :role_id => role.id}
      }.to change(Role, :count).by(-1)
    end

    it "destroys the user associated with the requested role if the user has no other roles" do
      role = create(:role, :provider => @current_user.current_provider)
      expect {
        post :delete_role, {:provider_id => @current_user.current_provider.id, :role_id => role.id}
      }.to change(User, :count).by(-1)
    end

    it "does not destroy the user associated with the requested role if the user has other roles" do
      role = create(:role, :provider => @current_user.current_provider)
      create(:role, :user => role.user)
      expect {
        post :delete_role, {:provider_id => @current_user.current_provider.id, :role_id => role.id}
      }.to_not change(User, :count)
    end

    it "redirects to the provider" do
      role = create(:role, :provider => @current_user.current_provider)
      post :delete_role, {:provider_id => @current_user.current_provider.id, :role_id => role.id}
      expect(response).to redirect_to(@current_user.current_provider)
    end
  end

  describe "POST #change_dispatch" do
    it "updates the dispatch flag on the requested provider" do
      initial_dispatch_value = @current_user.current_provider.dispatch
      expect {
        post :change_dispatch, {:id => @current_user.current_provider.id, :dispatch => false}
      }.to change{ @current_user.current_provider.reload.dispatch }.from(initial_dispatch_value).to(false)
    end

    it "redirects to the provider" do
      post :change_dispatch, {:id => @current_user.current_provider.id, :dispatch => true}
      expect(response).to redirect_to(@current_user.current_provider)
    end
  end

  describe "POST #change_scheduling" do
    
    it "updates the scheduling flag on the requested provider" do
      expect {
        post :change_scheduling, {:id => @current_user.current_provider.id, :scheduling => false}
      }.to change{ @current_user.current_provider.reload.scheduling }.from(true).to(false)
    end

    it "redirects to the provider" do
      post :change_scheduling, {:id => @current_user.current_provider.id, :scheduling => true}
      expect(response).to redirect_to(@current_user.current_provider)
    end
  end

  describe "POST #change_allow_trip_entry_from_runs_page" do
    it "updates the allow_trip_entry_from_runs_page flag on the requested provider" do
      expect {
        post :change_allow_trip_entry_from_runs_page, {:id => @current_user.current_provider.id, :allow_trip_entry_from_runs_page => false}
      }.to change{ @current_user.current_provider.reload.allow_trip_entry_from_runs_page }.from(nil).to(false)
    end

    it "redirects to the provider" do
      post :change_allow_trip_entry_from_runs_page, {:id => @current_user.current_provider.id, :allow_trip_entry_from_runs_page => true}
      expect(response).to redirect_to(@current_user.current_provider)
    end
  end

  describe "POST #change_reimbursement_rates" do
    context "with valid attributes" do
      Provider::REIMBURSEMENT_ATTRIBUTES.each do |attr|
        it "updates the reimbursement rates on the requested provider" do
          expect {
            post :change_reimbursement_rates, {:id => @current_user.current_provider.id, attr => 0.99}
          }.to change{ @current_user.current_provider.reload.send(attr) }.from(nil).to(0.99)
        end
      end

      it "redirects to the provider" do
        post :change_reimbursement_rates, {:id => @current_user.current_provider.id, Provider::REIMBURSEMENT_ATTRIBUTES.first => 0}
        expect(response).to redirect_to(@current_user.current_provider)
      end
    end
    
    context "with invalid attributes" do
      it "doesn't change the requested provider" do
        expect {
          post :change_reimbursement_rates, {:id => @current_user.current_provider.id, :bad_reimbursement_rate => 0.99}
        }.to_not change{ @current_user.current_provider.reload }
      end
    end
  end

  describe "POST #change_fields_required_for_run_completion" do
    it "updates the fields_required_for_run_completion flag on the requested provider" do
      expect {
        post :change_fields_required_for_run_completion, {:id => @current_user.current_provider.id, :fields_required_for_run_completion => Run::FIELDS_FOR_COMPLETION}
      }.to change{ @current_user.current_provider.reload.fields_required_for_run_completion }.from([])
    end

    it "redirects to the provider" do
      post :change_fields_required_for_run_completion, {:id => @current_user.current_provider.id, :fields_required_for_run_completion => []}
      expect(response).to redirect_to(@current_user.current_provider)
    end
  end

  describe "POST #save_region" do
    it "updates the region_nw_corner flag on the requested provider" do
      expect {
        post :save_region, {:id => @current_user.current_provider.id, :region_north => 1.0, :region_west => 1.0}
      }.to change{ @current_user.current_provider.reload.region_nw_corner }.from(nil)
    end

    it "updates the region_se_corner flag on the requested provider" do
      expect {
        post :save_region, {:id => @current_user.current_provider.id, :region_south => 1.0, :region_east => 1.0}
      }.to change{ @current_user.current_provider.reload.region_se_corner }.from(nil)
    end

    it "redirects to the provider" do
      post :save_region, {:id => @current_user.current_provider.id}
      expect(response).to redirect_to(provider_url @current_user.current_provider, anchor: "region")
    end
  end

  describe "POST #save_viewport" do
    it "updates the viewport_zoom flag on the requested provider" do
      expect {
        post :save_viewport, {:id => @current_user.current_provider.id, :viewport_lat => 1.0, :viewport_lng => 1.0}
      }.to change{ @current_user.current_provider.reload.viewport_zoom }.from(nil)
    end

    it "updates the viewport_center flag on the requested provider" do
      expect {
        post :save_viewport, {:id => @current_user.current_provider.id, :viewport_lat => 1.0, :viewport_lng => 1.0, :viewport_zoom => "1"}
      }.to change{ @current_user.current_provider.reload.viewport_center }.from(nil)
    end

    it "redirects to the provider" do
      post :save_viewport, {:id => @current_user.current_provider.id, :viewport_lat => 1.0, :viewport_lng => 1.0}
      expect(response).to redirect_to(provider_url @current_user.current_provider, anchor: "viewport")
    end
  end
  
end
