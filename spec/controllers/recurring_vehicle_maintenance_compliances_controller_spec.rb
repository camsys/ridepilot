require 'rails_helper'

RSpec.describe RecurringVehicleMaintenanceCompliancesController, type: :controller do
  login_admin_as_current_user

  # This should return the minimal set of attributes required to create a valid
  # RecurringVehicleMaintenanceCompliance. As you add validations to RecurringVehicleMaintenanceCompliance, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { attributes_for :recurring_vehicle_maintenance_compliance }

  let(:invalid_attributes) { attributes_for :recurring_vehicle_maintenance_compliance, event_name: nil }

  describe "GET #index" do
    it "assigns all recurring_vehicle_maintenance_compliances as @recurring_vehicle_maintenance_compliances" do
      recurring_vehicle_maintenance_compliance = create :recurring_vehicle_maintenance_compliance, provider: @current_user.current_provider
      get :index, {}
      expect(assigns(:recurring_vehicle_maintenance_compliances)).to eq([recurring_vehicle_maintenance_compliance])
    end
  end

  describe "GET #show" do
    it "assigns the requested recurring_vehicle_maintenance_compliance as @recurring_vehicle_maintenance_compliance" do
      recurring_vehicle_maintenance_compliance = create :recurring_vehicle_maintenance_compliance, provider: @current_user.current_provider
      get :show, {:id => recurring_vehicle_maintenance_compliance.to_param}
      expect(assigns(:recurring_vehicle_maintenance_compliance)).to eq(recurring_vehicle_maintenance_compliance)
    end
  end

  describe "GET #new" do
    it "assigns a new recurring_vehicle_maintenance_compliance as @recurring_vehicle_maintenance_compliance" do
      get :new, {}
      expect(assigns(:recurring_vehicle_maintenance_compliance)).to be_a_new(RecurringVehicleMaintenanceCompliance)
    end
  end

  describe "GET #edit" do
    it "assigns the requested recurring_vehicle_maintenance_compliance as @recurring_vehicle_maintenance_compliance" do
      recurring_vehicle_maintenance_compliance = create :recurring_vehicle_maintenance_compliance, provider: @current_user.current_provider
      get :edit, {:id => recurring_vehicle_maintenance_compliance.to_param}
      expect(assigns(:recurring_vehicle_maintenance_compliance)).to eq(recurring_vehicle_maintenance_compliance)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new RecurringVehicleMaintenanceCompliance" do
        expect {
          post :create, {:recurring_vehicle_maintenance_compliance => valid_attributes}
        }.to change(RecurringVehicleMaintenanceCompliance, :count).by(1)
      end

      it "assigns a newly created recurring_vehicle_maintenance_compliance as @recurring_vehicle_maintenance_compliance" do
        post :create, {:recurring_vehicle_maintenance_compliance => valid_attributes}
        expect(assigns(:recurring_vehicle_maintenance_compliance)).to be_a(RecurringVehicleMaintenanceCompliance)
        expect(assigns(:recurring_vehicle_maintenance_compliance)).to be_persisted
      end

      it "redirects to the created recurring_vehicle_maintenance_compliance" do
        post :create, {:recurring_vehicle_maintenance_compliance => valid_attributes}
        expect(response).to redirect_to(RecurringVehicleMaintenanceCompliance.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved recurring_vehicle_maintenance_compliance as @recurring_vehicle_maintenance_compliance" do
        post :create, {:recurring_vehicle_maintenance_compliance => invalid_attributes}
        expect(assigns(:recurring_vehicle_maintenance_compliance)).to be_a_new(RecurringVehicleMaintenanceCompliance)
      end

      it "re-renders the 'new' template" do
        post :create, {:recurring_vehicle_maintenance_compliance => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {{
        event_name: "My new event name"
      }}

      it "updates the requested recurring_vehicle_maintenance_compliance" do
        recurring_vehicle_maintenance_compliance = create :recurring_vehicle_maintenance_compliance, provider: @current_user.current_provider
        put :update, {:id => recurring_vehicle_maintenance_compliance.to_param, :recurring_vehicle_maintenance_compliance => new_attributes}
        recurring_vehicle_maintenance_compliance.reload
        expect(recurring_vehicle_maintenance_compliance.event_name).to eq "My new event name"
      end

      it "assigns the requested recurring_vehicle_maintenance_compliance as @recurring_vehicle_maintenance_compliance" do
        recurring_vehicle_maintenance_compliance = create :recurring_vehicle_maintenance_compliance, provider: @current_user.current_provider
        put :update, {:id => recurring_vehicle_maintenance_compliance.to_param, :recurring_vehicle_maintenance_compliance => valid_attributes}
        expect(assigns(:recurring_vehicle_maintenance_compliance)).to eq(recurring_vehicle_maintenance_compliance)
      end

      it "redirects to the recurring_vehicle_maintenance_compliance" do
        recurring_vehicle_maintenance_compliance = create :recurring_vehicle_maintenance_compliance, provider: @current_user.current_provider
        put :update, {:id => recurring_vehicle_maintenance_compliance.to_param, :recurring_vehicle_maintenance_compliance => valid_attributes}
        expect(response).to redirect_to(recurring_vehicle_maintenance_compliance)
      end
    end

    context "with invalid params" do
      it "assigns the recurring_vehicle_maintenance_compliance as @recurring_vehicle_maintenance_compliance" do
        recurring_vehicle_maintenance_compliance = create :recurring_vehicle_maintenance_compliance, provider: @current_user.current_provider
        put :update, {:id => recurring_vehicle_maintenance_compliance.to_param, :recurring_vehicle_maintenance_compliance => invalid_attributes}
        expect(assigns(:recurring_vehicle_maintenance_compliance)).to eq(recurring_vehicle_maintenance_compliance)
      end

      it "re-renders the 'edit' template" do
        recurring_vehicle_maintenance_compliance = create :recurring_vehicle_maintenance_compliance, provider: @current_user.current_provider
        put :update, {:id => recurring_vehicle_maintenance_compliance.to_param, :recurring_vehicle_maintenance_compliance => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "GET #delete" do
    it "assigns the requested recurring_vehicle_maintenance_compliance as @recurring_vehicle_maintenance_compliance" do
      recurring_vehicle_maintenance_compliance = create :recurring_vehicle_maintenance_compliance, provider: @current_user.current_provider
      get :delete, {:id => recurring_vehicle_maintenance_compliance.to_param}
      expect(assigns(:recurring_vehicle_maintenance_compliance)).to eq(recurring_vehicle_maintenance_compliance)
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested recurring_vehicle_maintenance_compliance" do
      recurring_vehicle_maintenance_compliance = create :recurring_vehicle_maintenance_compliance, provider: @current_user.current_provider
      expect {
        delete :destroy, {:id => recurring_vehicle_maintenance_compliance.to_param}
      }.to change(RecurringVehicleMaintenanceCompliance, :count).by(-1)
    end

    it "redirects to the recurring_vehicle_maintenance_compliances list" do
      recurring_vehicle_maintenance_compliance = create :recurring_vehicle_maintenance_compliance, provider: @current_user.current_provider
      delete :destroy, {:id => recurring_vehicle_maintenance_compliance.to_param}
      expect(response).to redirect_to(recurring_vehicle_maintenance_compliances_url)
    end
  end

  describe "GET #schedule_preview" do
    it "assigns a newly created but unsaved recurring_vehicle_maintenance_compliance as @recurring_vehicle_maintenance_compliance" do
      get :schedule_preview, {:recurring_vehicle_maintenance_compliance => valid_attributes}
      expect(assigns(:recurring_vehicle_maintenance_compliance)).to be_a_new(RecurringVehicleMaintenanceCompliance)
    end

    it "assigns the preview dates to as @schedule_preview" do
      get :schedule_preview, {:recurring_vehicle_maintenance_compliance => valid_attributes}
      expect(assigns(:schedule_preview)).not_to be_nil
    end

    it "renders the 'schedule_preview' partial" do
      get :schedule_preview, {:recurring_vehicle_maintenance_compliance => valid_attributes}
      expect(response).to render_template(partial: "_schedule_preview")
    end
  end

  describe "GET #future_schedule_preview" do
    it "assigns a newly created but unsaved recurring_vehicle_maintenance_compliance as @recurring_vehicle_maintenance_compliance" do
      get :future_schedule_preview, {:recurring_vehicle_maintenance_compliance => valid_attributes}
      expect(assigns(:recurring_vehicle_maintenance_compliance)).to be_a_new(RecurringVehicleMaintenanceCompliance)
    end

    it "assigns the preview dates to as @future_schedule_preview" do
      get :future_schedule_preview, {:recurring_vehicle_maintenance_compliance => valid_attributes}
      expect(assigns(:future_schedule_preview)).not_to be_nil
    end

    it "renders the 'future_schedule_preview' partial" do
      get :future_schedule_preview, {:recurring_vehicle_maintenance_compliance => valid_attributes}
      expect(response).to render_template(partial: "_future_schedule_preview")
    end
  end

  describe "GET #compliance_based_schedule_preview" do
    it "assigns a newly created but unsaved recurring_vehicle_maintenance_compliance as @recurring_vehicle_maintenance_compliance" do
      get :compliance_based_schedule_preview, {:recurring_vehicle_maintenance_compliance => valid_attributes}
      expect(assigns(:recurring_vehicle_maintenance_compliance)).to be_a_new(RecurringVehicleMaintenanceCompliance)
    end

    it "assigns the preview dates to as @compliance_based_schedule_preview" do
      get :compliance_based_schedule_preview, {:recurring_vehicle_maintenance_compliance => valid_attributes}
      expect(assigns(:compliance_based_schedule_preview)).not_to be_nil
    end

    it "renders the 'compliance_based_schedule_preview' partial" do
      get :compliance_based_schedule_preview, {:recurring_vehicle_maintenance_compliance => valid_attributes}
      expect(response).to render_template(partial: "_compliance_based_schedule_preview")
    end
  end
end
