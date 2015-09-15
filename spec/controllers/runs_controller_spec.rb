require "rails_helper"

RSpec.describe RunsController, type: :controller do
  login_admin_as_current_user

  # This should return the minimal set of attributes required to create a valid
  # Run. As you add validations to Run, be sure to
  # adjust the attributes here as well.
  before(:each) do
    @driver = create(:driver)
    @vehicle = create(:vehicle)
  end

  let(:valid_attributes) {
    attributes_for(:run, :driver_id => @driver.id, :vehicle_id => @vehicle.id)
  }

  let(:invalid_attributes) {
    attributes_for(:run, :date => "")
  }

  describe "GET #index" do
    it "assigns all runs as @runs" do
      run = create(:run, :provider => @current_user.current_provider)
      get :index, {}
      expect(assigns(:runs)).to eq([run])
    end
  end

  describe "GET #new" do
    it "assigns a new run as @run" do
      get :new, {}
      expect(assigns(:run)).to be_a_new(Run)
    end
  end

  describe "GET #edit" do
    it "assigns the requested run as @run" do
      run = create(:run, :provider => @current_user.current_provider)
      get :edit, {:id => run.to_param}
      expect(assigns(:run)).to eq(run)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Run" do
        expect {
          post :create, {:run => valid_attributes}
        }.to change(Run, :count).by(1)
      end

      it "assigns a newly created run as @run" do
        post :create, {:run => valid_attributes}
        expect(assigns(:run)).to be_a(Run)
        expect(assigns(:run)).to be_persisted
      end

      it "redirects to the created run" do
        post :create, {:run => valid_attributes}
        expect(response).to redirect_to(runs_path(date_range(Run.new(valid_attributes))))
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved run as @run" do
        post :create, {:run => invalid_attributes}
        expect(assigns(:run)).to be_a_new(Run)
      end

      it "re-renders the 'new' template" do
        post :create, {:run => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          :name => "MyString",
          :date => "2015-02-24 00:00:00",
          :start_odometer => 1,
          :end_odometer => 2,
          :scheduled_start_time => "2015-02-24 02:40",
          :scheduled_end_time => "2015-02-24 02:41",
          :unpaid_driver_break_time => 1,
          :vehicle_id => create(:vehicle, :provider => @current_user.current_provider).id,
          :driver_id => create(:driver, :provider => @current_user.current_provider).id,
          :paid => false,
          :complete => false,
          :actual_start_time => "2015-02-24 02:40",
          :actual_end_time => "2015-02-24 02:41",
        }
      }

      it "updates the requested run" do
        run = create(:run, :provider => @current_user.current_provider, :name => "Something")
        expect {
          put :update, {:id => run.to_param, :run => new_attributes}
        }.to change{ run.reload.name }.from("Something").to("MyString")
      end

      it "accepts nested trip attributes" do        
        run = create(:run, :provider => @current_user.current_provider)
        trip = create(:trip, :provider => @current_user.current_provider, :run => run, :trip_purpose => create(:trip_purpose, name: "Shopping"))
        expect {
          put :update, {:id => run.to_param, :run => new_attributes.merge({
            :trips_attributes => { "0" => { :id => trip.id, :trip_purpose_id => create(:trip_purpose, name: "Eating").id }}}
          )}
        }.to change{ trip.reload.trip_purpose.name }.from("Shopping").to("Eating")
      end

      it "assigns the requested run as @run" do
        run = create(:run, :provider => @current_user.current_provider)
        put :update, {:id => run.to_param, :run => valid_attributes}
        expect(assigns(:run)).to eq(run)
      end

      it "redirects to the run" do
        run = create(:run, :provider => @current_user.current_provider)
        put :update, {:id => run.to_param, :run => valid_attributes}
        expect(response).to redirect_to(runs_path(date_range(run)))
      end
    end

    context "with invalid params" do
      it "assigns the run as @run" do
        run = create(:run, :provider => @current_user.current_provider)
        put :update, {:id => run.to_param, :run => invalid_attributes}
        expect(assigns(:run)).to eq(run)
      end

      it "re-renders the 'edit' template" do
        run = create(:run, :provider => @current_user.current_provider)
        put :update, {:id => run.to_param, :run => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested run" do
      run = create(:run, :provider => @current_user.current_provider)
      expect {
        delete :destroy, {:id => run.to_param}
      }.to change(Run, :count).by(-1)
    end

    it "redirects to the runs list" do
      run = create(:run, :provider => @current_user.current_provider)
      delete :destroy, {:id => run.to_param}
      expect(response).to redirect_to(runs_path(date_range(run)))
    end
  end
  
  describe "GET #for_date" do
    it "assigns incomplete runs scheduled for the requested date as @runs" do
      run_1 = create(:run, :provider => @current_user.current_provider, :date => Date.today.in_time_zone)
      run_2 = create(:run, :provider => @current_user.current_provider, :date => Date.yesterday.in_time_zone)
      run_3 = create(:run, :provider => @current_user.current_provider, :date => Date.yesterday.in_time_zone)
      run_3.update_attribute(:complete, true)
      get :for_date, {:date => Date.yesterday.in_time_zone}
      expect(assigns(:runs)).to_not include(run_1)
      expect(assigns(:runs)).to_not include(run_3)
      expect(assigns(:runs)).to include(run_2)
    end
    
    it "responds with JSON" do
      get :for_date, {:date => Date.yesterday.in_time_zone}
      expect(response.content_type).to eq("application/json")
    end

    it "include matching address info in the json response" do
      run = create(:run, :provider => @current_user.current_provider, :date => Date.today.in_time_zone)
      get :for_date, {:date => Date.today.in_time_zone}
      json = JSON.parse(response.body)
      expect(json).to be_a(Array)
      expect(json.first["id"]).to be_a(Integer)
      expect(json.first["id"]).to eq(run.id)
    end

    it "include a new cab trip in the json response" do
      get :for_date, {:date => Date.today.in_time_zone}
      json = JSON.parse(response.body)
      expect(json).to be_a(Array)
      expect(json.first["id"]).to be_a(Integer)
      expect(json.first["id"]).to eq(-1)
      expect(json.first["label"]).to eq("Cab")
    end
  end
  
  describe "GET #uncompleted_runs" do
    it "assigns incomplete runs as @runs" do
      run_1 = create(:run, :provider => @current_user.current_provider)
      run_1.update_attribute(:complete, true)
      run_2 = create(:run, :provider => @current_user.current_provider)
      get :uncompleted_runs, {}
      expect(assigns(:runs)).to_not include(run_1)
      expect(assigns(:runs)).to include(run_2)
    end

    it "renders the 'index' template" do
      get :uncompleted_runs, {}
      expect(response).to render_template("index")
    end
  end

  private
  
  def date_range(run)
    if run.date
      week_start = run.date.beginning_of_week
      {:start => week_start.to_time.to_i, :end => (week_start + 6.days).to_time.to_i } 
    end    
  end

end
