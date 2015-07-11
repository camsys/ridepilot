require "rails_helper"

RSpec.describe TripsController, type: :controller do
  login_admin_as_current_user

  # This should return the minimal set of attributes required to create a valid
  # Trip. As you add validations to Trip, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    attributes_for(:trip,
      :customer_id => create(:customer, :provider => @current_user.current_provider).id,
      :pickup_address_id => create(:address, :provider => @current_user.current_provider).id,
      :dropoff_address_id => create(:address, :provider => @current_user.current_provider).id,
      :trip_purpose_id => create(:trip_purpose).id
    )
  }

  let(:invalid_attributes) {
    attributes_for(:trip, 
      :customer_id => create(:customer, :provider => @current_user.current_provider).id,
      :trip_purpose_id => nil
    )
  }

  describe "GET #index" do
    context "when responding to :html request" do
      it "assigns an empty array to @trips even if valid trips are found" do
        trip = create(:trip, :provider => @current_user.current_provider, :pickup_time => Time.now.in_time_zone)
        get :index, {}
        expect(assigns(:trips)).to eq([])
      end
    end
    
    context "when responding to a :json request" do
      it "responds with JSON" do
        get :index, {:format => "json"}
        expect(response.content_type).to eq("application/json")
      end

      it "assigns trips for the current week as @trips" do
        trip_1 = create(:trip, :provider => @current_user.current_provider, :pickup_time => Time.now.in_time_zone)
        trip_2 = create(:trip, :provider => @current_user.current_provider, :pickup_time => 1.week.from_now.in_time_zone)
        get :index, {:format => "json"}
        expect(assigns(:trips)).to include(trip_1)
        expect(assigns(:trips)).to_not include(trip_2)
      end
      
      it "renders matching trips in the events attribute of the json response" do
        trip = create(:trip, :provider => @current_user.current_provider, :pickup_time => Time.now.in_time_zone)
        get :index, {:format => "json"}
        json = JSON.parse(response.body)
        expect(json["events"]).to be_a(Array)
        expect(json["events"].first["id"]).to be_a(Integer)
        expect(json["events"].first["id"]).to eq(trip.id)
      end
      
      context "with rendered views" do
        render_views
      
        it "renders rows of HTML for matching trips in the row attribute of the json response" do
          pickup_time = Time.now.in_time_zone
          trip = create(:trip, :provider => @current_user.current_provider, :pickup_time => pickup_time)
          get :index, {:format => "json"}
          json = JSON.parse(response.body)
          expect(json["rows"]).to be_a(Array)
          expect(json["rows"].first).to include("<tr class=\"day\">")
          expect(json["rows"].first).to include(pickup_time.strftime('%A, %e-%b-%4Y'))
          expect(json["rows"].second).to include("<tr class=\"trip\">")
          expect(json["rows"].second).to include(edit_trip_path(trip))
        end
      end
      
      context "when specifying a start param" do
        it "assigns trips for the requested week as @trips" do
          trip_1 = create(:trip, :provider => @current_user.current_provider, :pickup_time => Time.now.in_time_zone)
          trip_2 = create(:trip, :provider => @current_user.current_provider, :pickup_time => 1.week.from_now.in_time_zone)
          get :index, {:start => 1.week.from_now.in_time_zone.at_beginning_of_week.to_i, :end => 1.week.from_now.in_time_zone.at_end_of_week.to_i, :format => "json"}
          expect(assigns(:trips)).to_not include(trip_1)
          expect(assigns(:trips)).to include(trip_2)
        end
      end
    end
  end

  describe "GET #new" do
    it "assigns a new trip as @trip" do
      get :new, {}
      expect(assigns(:trip)).to be_a_new(Trip)
    end
    
    context "when responding to :html request" do
      it "renders the 'new' template" do
        get :new, {}
        expect(response).to render_template("new")
      end
    end
    
    context "when responding to a :js request" do
      it "responds with JSON" do
        get :new, {:format => "js"}
        expect(response.content_type).to eq("text/json")
      end
      
      context "with rendered views" do
        render_views
        
        it "responds with the 'new' form partial in the JS response" do
          get :new, {:format => "js"}
          json = JSON.parse(response.body)
          expect(json["form"]).to be_a(String)
          expect(json["form"]).to include("action=\"#{trips_path}\"")
        end
      end
    end
  end

  describe "GET #edit" do
    it "assigns the requested trip as @trip" do
      trip = create(:trip, :provider => @current_user.current_provider)
      get :edit, {:id => trip.to_param}
      expect(assigns(:trip)).to eq(trip)
    end
    
    context "when responding to :html request" do
      it "renders the 'edit' template" do
        trip = create(:trip, :provider => @current_user.current_provider)
        get :edit, {:id => trip.to_param}
        expect(response).to render_template("edit")
      end
    end
    
    context "when responding to a :js request" do
      it "responds with JSON" do
        trip = create(:trip, :provider => @current_user.current_provider)
        get :edit, {:id => trip.to_param, :format => "js"}
        expect(response.content_type).to eq("text/json")
      end
      
      context "with rendered views" do
        render_views
        
        it "responds with the 'edit' form partial in the JS response" do
          trip = create(:trip, :provider => @current_user.current_provider)
          get :edit, {:id => trip.to_param, :format => "js"}
          json = JSON.parse(response.body)
          expect(json["form"]).to be_a(String)
          expect(json["form"]).to include("action=\"#{trip_path(trip)}\"")
        end
      end
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Trip" do
        expect {
          post :create, {:trip => valid_attributes}
        }.to change(Trip, :count).by(1)
      end

      it "assigns a newly created trip as @trip" do
        post :create, {:trip => valid_attributes}
        expect(assigns(:trip)).to be_a(Trip)
        expect(assigns(:trip)).to be_persisted
      end

      context "when responding to :html request" do
        context "when both params[trip][run_id] and params[run_id] are present and equal" do
          it "redirects to the requested run" do
            run = create(:run, :provider => @current_user.current_provider)
            post :create, {:trip => valid_attributes.merge({:run_id => run.id}), :run_id => run.id}
            expect(response).to redirect_to(edit_run_path(run))
          end
        end

        context "when run_id param is not present" do
          it "redirects to the trips list" do
            post :create, {:trip => valid_attributes}
            expect(response).to redirect_to(trips_url(:start => Trip.last.pickup_time.to_i))
          end
        end
      end
      
      context "when responding to a :js request" do
        it "responds with JSON" do
          post :create, {:trip => valid_attributes, :format => "js"}
          expect(response.content_type).to eq("text/json")
        end

        it "includes a successful status in the JS response" do
          post :create, {:trip => valid_attributes, :format => "js"}
          json = JSON.parse(response.body)
          expect(json["status"]).to be_a(String)
          expect(json["status"]).to eq("success")
        end

        context "with rendered views" do
          render_views
          
          it "responds with the runs/trip partial in the JS response" do
            post :create, {:trip => valid_attributes, :format => "js"}
            json = JSON.parse(response.body)
            expect(json["trip"]).to be_a(String)
            expect(json["trip"]).to include(edit_trip_path(Trip.last))
          end
        end
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved trip as @trip" do
        post :create, {:trip => invalid_attributes}
        expect(assigns(:trip)).to be_a_new(Trip)
      end

      context "when responding to :html request" do
        it "re-renders the 'new' template" do
          post :create, {:trip => invalid_attributes}
          expect(response).to render_template("new")
        end
      end
      
      context "when responding to a :js request" do
        it "responds with JSON" do
          post :create, {:trip => invalid_attributes, :format => "js"}
          expect(response.content_type).to eq("text/json")
        end
        
        it "includes a error status in the JS response" do
          post :create, {:trip => invalid_attributes, :format => "js"}
          json = JSON.parse(response.body)
          expect(json["status"]).to be_a(String)
          expect(json["status"]).to eq("error")
        end

        context "with rendered views" do
          render_views
          
          it "responds with the 'new' form partial in the JS response" do
            post :create, {:trip => invalid_attributes, :format => "js"}
            json = JSON.parse(response.body)
            expect(json["form"]).to be_a(String)
            expect(json["form"]).to include("action=\"#{trips_path}\"")
          end
        end
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          :run_id => create(:run, :provider => @current_user.current_provider).id,
          :customer_id => create(:customer, :provider => @current_user.current_provider).id,
          :pickup_time => "2015-02-25 08:49",
          :appointment_time => "2015-02-25 08:50",
          :guest_count => 1,
          :attendant_count => 1,
          :group_size => 1,
          :pickup_address_id => create(:address, :provider => @current_user.current_provider).id,
          :dropoff_address_id => create(:address, :provider => @current_user.current_provider).id,
          :mobility_id => create(:mobility),
          :funding_source_id => create(:funding_source, :provider => @current_user.current_provider).id,
          :trip_purpose_id => create(:trip_purpose, name: 'New purpose').id,
          :trip_result_id => create(:trip_result).id,
          :notes => "MyText",
          :donation => "9.99",
          :customer_informed => false,
          :cab => false,
          :cab_notified => false,
          :guests => "MyText",
          :round_trip => false,
          :medicaid_eligible => false,
          :mileage => 1,
          :service_level_id => create(:service_level),
        }
      }

      it "updates the requested trip" do
        trip = create(:trip, :provider => @current_user.current_provider, :trip_purpose => create(:trip_purpose, name: 'Something'))
        expect {
          put :update, {:id => trip.to_param, :trip => new_attributes}
        }.to change{ trip.reload.trip_purpose.name }.from("Something").to("New purpose")
      end

      it "assigns the requested trip as @trip" do
        trip = create(:trip, :provider => @current_user.current_provider)
        put :update, {:id => trip.to_param, :trip => valid_attributes}
        expect(assigns(:trip)).to eq(trip)
      end

      context "when responding to :html request" do
        it "redirects to the trips list" do
          trip = create(:trip, :provider => @current_user.current_provider)
          put :update, {:id => trip.to_param, :trip => valid_attributes}
          expect(response).to redirect_to(trips_url)
        end
      end

      context "when responding to a :js request" do
        it "responds with JSON" do
          trip = create(:trip, :provider => @current_user.current_provider)
          put :update, {:id => trip.to_param, :trip => valid_attributes, :format => "js"}
          expect(response.content_type).to eq("text/json")
        end

        it "includes a successful status in the JS response" do
          trip = create(:trip, :provider => @current_user.current_provider)
          put :update, {:id => trip.to_param, :trip => valid_attributes, :format => "js"}
          json = JSON.parse(response.body)
          expect(json["status"]).to be_a(String)
          expect(json["status"]).to eq("success")
        end
      end
    end

    context "with invalid params" do
      it "assigns the trip as @trip" do
        trip = create(:trip, :provider => @current_user.current_provider)
        put :update, {:id => trip.to_param, :trip => invalid_attributes}
        expect(assigns(:trip)).to eq(trip)
      end

      context "when responding to :html request" do
        it "re-renders the 'edit' template" do
          trip = create(:trip, :provider => @current_user.current_provider)
          put :update, {:id => trip.to_param, :trip => invalid_attributes}
          expect(response).to render_template("edit")
        end
      end

      context "when responding to a :js request" do
        it "responds with JSON" do
          trip = create(:trip, :provider => @current_user.current_provider)
          put :update, {:id => trip.to_param, :trip => invalid_attributes, :format => "js"}
          expect(response.content_type).to eq("text/json")
        end
        
        it "includes a error status in the JS response" do
          trip = create(:trip, :provider => @current_user.current_provider)
          put :update, {:id => trip.to_param, :trip => invalid_attributes, :format => "js"}
          json = JSON.parse(response.body)
          expect(json["status"]).to be_a(String)
          expect(json["status"]).to eq("error")
        end

        context "with rendered views" do
          render_views
          
          it "responds with the 'edit' form partial in the JS response" do
            trip = create(:trip, :provider => @current_user.current_provider)
            put :update, {:id => trip.to_param, :trip => invalid_attributes, :format => "js"}
            json = JSON.parse(response.body)
            expect(json["form"]).to be_a(String)
            expect(json["form"]).to include("action=\"#{trip_path(trip)}\"")
          end
        end
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested trip" do
      trip = create(:trip, :provider => @current_user.current_provider)
      expect {
        delete :destroy, {:id => trip.to_param}
      }.to change(Trip, :count).by(-1)
    end

    context "when responding to :html request" do
      it "redirects to the trips list" do
        trip = create(:trip, :provider => @current_user.current_provider)
        delete :destroy, {:id => trip.to_param}
        expect(response).to redirect_to(trips_url)
      end
    end

    context "when responding to a :js request" do
      it "responds with JSON" do
        trip = create(:trip, :provider => @current_user.current_provider)
        delete :destroy, {:id => trip.to_param, :format => "js"}
        expect(response.content_type).to eq("text/json")
      end

      it "includes a successful status in the JS response" do
        trip = create(:trip, :provider => @current_user.current_provider)
        delete :destroy, {:id => trip.to_param, :format => "js"}
        json = JSON.parse(response.body)
        expect(json["status"]).to be_a(String)
        expect(json["status"]).to eq("success")
      end
    end
  end

  describe "POST #confirm" do
    it "assigns the requested trip as @trip" do
      trip = create(:trip, :provider => @current_user.current_provider)
      post :confirm, {:trip_id => trip.to_param}
      expect(assigns(:trip)).to eq(trip)
    end
    
    it "updates the trip_result of the requested trip to \"COMP\"" do
      create(:trip_result, code:"COMP", name: 'Complete')
      trip = create(:trip, :provider => @current_user.current_provider)
      expect {
        post :confirm, {:trip_id => trip.to_param}
      }.to change{ trip.reload.trip_result.try(:code) }.to("COMP")
    end

    it "redirects to the unscheduled action" do
      trip = create(:trip, :provider => @current_user.current_provider)
      post :confirm, {:trip_id => trip.to_param}
      expect(response).to redirect_to(unscheduled_trips_path)
    end
  end
  
  describe "POST #no_show" do
    it "assigns the requested trip as @trip" do
      trip = create(:trip, :provider => @current_user.current_provider)
      post :no_show, {:trip_id => trip.to_param}
      expect(assigns(:trip)).to eq(trip)
    end
    
    it "updates the trip_result of the requested trip to \"NS\"" do
      comp_result = create(:trip_result, code:"NS", name: 'No-show')
      trip = create(:trip, :provider => @current_user.current_provider)
      expect {
        post :no_show, {:trip_id => trip.to_param}
      }.to change{ trip.reload.trip_result.try(:code) }.to("NS")
    end

    it "redirects to the reconcile_cab action" do
      trip = create(:trip, :provider => @current_user.current_provider)
      post :no_show, {:trip_id => trip.to_param}
      expect(response).to redirect_to(reconcile_cab_trips_path)
    end
  end
    
  describe "POST #reached" do
    it "assigns the requested trip as @trip" do
      trip = create(:trip, :provider => @current_user.current_provider)
      post :reached, {:trip_id => trip.to_param}
      expect(assigns(:trip)).to eq(trip)
    end
    
    it "mark the user as having been informed that their trip has been approved or turned down" do
      trip = create(:trip, :provider => @current_user.current_provider)
      expect {
        post :reached, {:trip_id => trip.to_param}
      }.to change{[
        trip.reload.called_back_by,
        trip.reload.customer_informed
      ]}.to([@current_user, true])
      expect(trip.called_back_at).to be_within(1.minute).of(Time.now)
    end

    it "redirects to the trips_requiring_callback action" do
      trip = create(:trip, :provider => @current_user.current_provider)
      post :reached, {:trip_id => trip.to_param}
      expect(response).to redirect_to(trips_requiring_callback_trips_path)
    end
  end
    
  describe "POST #send_to_cab" do
    it "assigns the requested trip as @trip" do
      trip = create(:trip, :provider => @current_user.current_provider)
      post :send_to_cab, {:trip_id => trip.to_param}
      expect(assigns(:trip)).to eq(trip)
    end
    
    it "marks the trip as a cab trip and sets the trip_result \"COMP\"" do
      comp_result = create(:trip_result, code:"COMP", name: 'Complete')
      trip = create(:trip, :provider => @current_user.current_provider)
      expect {
        post :send_to_cab, {:trip_id => trip.to_param}
      }.to change{[
        trip.reload.trip_result.try(:code),
        trip.reload.cab,
        trip.reload.cab_notified        
      ]}.to([
        "COMP",
        true,
        false
      ])
    end

    it "redirects to the reconcile_cab action" do
      trip = create(:trip, :provider => @current_user.current_provider)
      post :send_to_cab, {:trip_id => trip.to_param}
      expect(response).to redirect_to(reconcile_cab_trips_path)
    end
  end
    
  describe "POST #turndown" do
    it "assigns the requested trip as @trip" do
      trip = create(:trip, :provider => @current_user.current_provider)
      post :turndown, {:trip_id => trip.to_param}
      expect(assigns(:trip)).to eq(trip)
    end
    
    it "updates the trip_result of the requested trip to \"TD\"" do
      comp_result = create(:trip_result, code:"TD", name: 'Turned down')
      trip = create(:trip, :provider => @current_user.current_provider)
      expect {
        post :turndown, {:trip_id => trip.to_param}
      }.to change{ trip.reload.trip_result.try(:code) }.to("TD")
    end

    it "redirects to the unscheduled action" do
      trip = create(:trip, :provider => @current_user.current_provider)
      post :turndown, {:trip_id => trip.to_param}
      expect(response).to redirect_to(unscheduled_trips_path)
    end
  end  

  describe "GET #reconcile_cab" do
    #the cab company has sent a log of all trips in the past [time period]
    #we want to mark some trips as no-shows.  This will be a paginated
    #list of trips
    
    it "assigns complete and no-show cab trips to @trips" do
      td_result = create(:trip_result, code:"TD", name: "Turned down ")
      comp_result = create(:trip_result, code:"COMP", name: 'Complete')
      ns_result = create(:trip_result, code: 'NS', name:"No-show")

      trip_1 = create(:cab_trip, :provider => @current_user.current_provider, :trip_result => ns_result)
      trip_2 = create(:cab_trip, :provider => @current_user.current_provider, :trip_result => comp_result)
      trip_3 = create(:trip, :provider => @current_user.current_provider, :trip_result => comp_result)
      trip_4 = create(:cab_trip, :provider => @current_user.current_provider, :trip_result => td_result)
      get :reconcile_cab, {}
      expect(assigns(:trips)).to include(trip_1)
      expect(assigns(:trips)).to include(trip_2)
      expect(assigns(:trips)).to_not include(trip_3)
      expect(assigns(:trips)).to_not include(trip_4)
    end
  end
  
  describe "GET #trips_requiring_callback" do
    #The trip coordinator has made decisions on whether to confirm or
    #turn down trips.  Now they want to call back the customer to tell
    #them what's happened.  This is a list of all customers who have
    #not been marked as informed, ordered by when they were last
    #called.

    it "assigns future trips for customers that have not yet been informed to @trips" do
      trip_1 = create(:trip, :provider => @current_user.current_provider, :customer_informed => false, :pickup_time => Date.tomorrow.in_time_zone)
      trip_2 = create(:trip, :provider => @current_user.current_provider, :customer_informed => true,  :pickup_time => Date.tomorrow.in_time_zone)
      trip_3 = create(:trip, :provider => @current_user.current_provider, :customer_informed => false, :pickup_time => Date.yesterday.in_time_zone)
      get :trips_requiring_callback, {}
      expect(assigns(:trips)).to include(trip_1)
      expect(assigns(:trips)).to_not include(trip_2)
      expect(assigns(:trips)).to_not include(trip_3)
    end
  end
  
  describe "GET #unscheduled" do
    #The trip coordinatior wants to confirm or turn down individual
    #trips.  This is a list of all trips that haven't been decided
    #on yet.

    it "assigns future trips without a trip result to @trips" do
      ns_result = create(:trip_result, code:"NS", name: 'No-show')
      trip_1 = create(:trip, :provider => @current_user.current_provider, :trip_result => nil,   :pickup_time => Date.tomorrow.in_time_zone)
      trip_2 = create(:trip, :provider => @current_user.current_provider, :trip_result => ns_result, :pickup_time => Date.tomorrow.in_time_zone)
      trip_3 = create(:trip, :provider => @current_user.current_provider, :trip_result => nil,   :pickup_time => Date.yesterday.in_time_zone)
      get :unscheduled, {}
      expect(assigns(:trips)).to include(trip_1)
      expect(assigns(:trips)).to_not include(trip_2)
      expect(assigns(:trips)).to_not include(trip_3)
    end
  end
  
end
