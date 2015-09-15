require "rails_helper"

RSpec.describe UsersController, type: :controller do
  login_admin_as_current_user

  # This should return the minimal set of attributes required to create a valid
  # User. As you add validations to User, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    attributes_for(:user)
  }

  let(:invalid_attributes) {
    attributes_for(:user, :password => '')
  }

  describe "GET #new_user" do
    it "assigns a new user as @user" do
      get :new_user, {}
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe "POST #create_user" do
    context "with valid params" do
      context "creating a new user" do        
        # NOTE passwords are generated automatically, any set will be ignored
      
        it "creates a new User" do
          expect {
            post :create_user, {:user => valid_attributes, :role => {:level => 50}}
          }.to change(User, :count).by(1)
        end

        it "assigns a newly created user as @user" do
          post :create_user, {:user => valid_attributes, :role => {:level => 50}}
          expect(assigns(:user)).to be_a(User)
          expect(assigns(:user)).to be_persisted
        end

        it "assigns the user to a new role for the current provider" do
          post :create_user, {:user => valid_attributes, :role => {:level => 50}}
          expect(assigns(:role)).to be_a(Role)
          expect(assigns(:role)).to be_persisted
          expect(assigns(:role).user).to eq(assigns(:user))
          expect(assigns(:role).provider).to eq(@current_user.current_provider)
          expect(assigns(:role).level).to eq(50)
        end

        it "redirects to the current provider" do
          post :create_user, {:user => valid_attributes, :role => {:level => 50}}
          expect(response).to redirect_to(@current_user.current_provider)
        end
      end
      
      context "updating an existing user" do
        before(:each) do
          @new_user = create(:user)
        end
        
        it "does not create a new User" do
          expect {
            post :create_user, {:user => {:email => @new_user.email}, :role => {:level => 50}}
          }.to_not change(User, :count)
        end

        it "assigns the user to a new role for the current provider" do
          post :create_user, {:user => {:email => @new_user.email}, :role => {:level => 50}}
          expect(assigns(:role)).to be_a(Role)
          expect(assigns(:role)).to be_persisted
          expect(assigns(:role).user).to eq(@new_user)
          expect(assigns(:role).provider).to eq(@current_user.current_provider)
          expect(assigns(:role).level).to eq(50)
        end

        it "redirects to the current provider" do
          post :create_user, {:user => {:email => @new_user.email}, :role => {:level => 50}}
          expect(response).to redirect_to(@current_user.current_provider)
        end
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved user as @user" do
        post :create_user, {:user => invalid_attributes}
        expect(assigns(:user)).to be_a_new(User)
      end

      it "re-renders the 'new_user' template" do
        post :create_user, {:user => invalid_attributes}
        expect(response).to render_template("new_user")
      end
    end
  end

  describe "GET #show_change_password" do
    it "assigns the current user as @user" do
      get :show_change_password, {}
      expect(assigns(:user)).to eq(@current_user)
    end
  end

  describe "PUT #change_password" do
    context "with valid params" do
      let(:new_attributes) {{
        :current_password => attributes_for(:user)[:password],
        :password => "new password 12345",
        :password_confirmation => "new password 12345"
      }}

      it "updates the requested user's password" do
        expect {
          put :change_password, {:user => new_attributes}
        }.to change { @current_user.reload.encrypted_password }
      end

      it "signs the user in again" do
        skip "Unable to test here as nothing in the user's record or session that changes that we can check"
        expect {
          put :change_password, {:user => new_attributes}
        }.to change { @current_user.reload.last_sign_in_at }
      end

      it "redirects to the home page" do
        put :change_password, {:user => new_attributes}
        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid params" do
      it "re-renders the 'show_change_password' template" do
        put :change_password, {:user => invalid_attributes}
        expect(response).to render_template("show_change_password")
      end
    end
  end

  describe "GET #show_change_expiration" do
    before do
      @user = create :user
    end
    
    it "assigns the requested user as @user" do
      get :show_change_expiration, {id: @user.id}
      expect(assigns(:user)).to eq(@user)
    end
  end

  describe "PUT #change_expiration" do
    before do
      @user = create :user, current_provider: @current_user.current_provider
      create :role, user: @user, provider: @user.current_provider, :level => 0
    end
    
    context "with valid params" do
      let(:expiration_attributes) {{
        :expires_at => "2015-02-25 08:50",
        :inactivation_reason => "retired"
      }}

      it "updates the requested user's expiration" do
        expect {
          put :change_expiration, {id: @user.id, :user => expiration_attributes}
        }.to change { [@user.reload.expires_at, @user.reload.inactivation_reason] }
      end

      it "redirects to the requested user's provider page" do
        put :change_expiration, {id: @user.id, :user => expiration_attributes}
        expect(response).to redirect_to(provider_path(@user.current_provider))
      end
    end
  end

  describe "POST #change_provider" do
    context "while logged in as a super admin" do
      before(:each) do
        sign_out @current_user
        @request.env["devise.mapping"] = Devise.mappings[:user]
        @current_user = create(:super_admin)
        sign_in @current_user
        @old_provider = @current_user.current_provider
        @new_provider = create(:provider)
      end

      it "updates the current user's current provider" do
        expect {
          post :change_provider, {:provider_id => @new_provider.id, :come_from => "/"}
        }.to change { @current_user.reload.current_provider_id }.from(@old_provider.id).to(@new_provider.id)
      end

      it "redirects to the new provider page" do
        post :change_provider, {:provider_id => @new_provider.id}
        expect(response).to redirect_to("/en/providers/#{@new_provider.id}")
      end
    end

    context "while logged in, but not as a super admin" do
      before(:each) do
        @new_provider = create(:provider)
      end

      it "does not update the current user's current provider" do
        expect {
          post :change_provider, {:provider_id => @new_provider.id, :come_from => "/"}
        }.not_to change { @current_user.reload.current_provider_id }
      end

      it "redirects to the new provider page" do
        post :change_provider, {:provider_id => @new_provider.id}
        expect(response).to redirect_to("/en/providers/#{@new_provider.id}")
      end
    end
  end
  
  describe "GET #check_session" do
    it "responds with JSON" do
      get :check_session, {}
      expect(response.content_type).to eq("application/json")
    end

    it "include an integer named last_request_at" do
      get :check_session, {}
      json = JSON.parse(response.body)
      expect(json["last_request_at"]).to be_a(Integer)
    end

    it "include an integer named timeout_in" do
      get :check_session, {}
      json = JSON.parse(response.body)
      expect(json["timeout_in"]).to be_a(Integer)
    end
  end

  describe "GET #touch_session" do
    it "responds with the string 'OK'" do
      get :touch_session, {}
      expect(response.body).to eq('OK')
    end
  end
end
