require "rails_helper"

RSpec.describe User, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  
  describe "role checks" do
    before(:each) do
      @user = create(:user)
      @editor = create(:editor)
      @admin = create(:admin)
      @super_admin = create(:super_admin)
    end

    it "reports editor capabilities" do
      expect(@user.editor?).to_not    be_truthy
      expect(@editor.editor?).to      be_truthy
      expect(@admin.editor?).to       be_truthy
      expect(@super_admin.editor?).to be_truthy
    end

    it "reports admin capabilities" do
      expect(@user.admin?).to_not    be_truthy
      expect(@editor.admin?).to_not  be_truthy
      expect(@admin.admin?).to       be_truthy
      expect(@super_admin.admin?).to be_truthy
    end

    it "reports super_admin capabilities" do
      expect(@user.super_admin?).to_not    be_truthy
      expect(@editor.super_admin?).to_not  be_truthy
      expect(@admin.super_admin?).to_not   be_truthy
      expect(@super_admin.super_admin?).to be_truthy
    end
  end

  describe "email" do
    it "is required" do
      user = build :user, email: ""
      expect(user.valid?).to be_falsey
      expect(user.errors.keys).to include :email
    end

    it "must be a valid format" do
      user = build :user, email: "m@m"
      expect(user.valid?).to be_falsey
      expect(user.errors.keys).to include :email

      user.email = "m@m.m"
      expect(user.valid?).to be_truthy
    end

    it "must be unique" do
      user_1 = create :user
      user_2 = build :user, email: user_1.email
      expect(user_2.valid?).to be_falsey
      expect(user_2.errors.keys).to include :email

      user_2.email = "different-#{user_1.email}"
      expect(user_2.valid?).to be_truthy
    end

    it "is automatically downcased upon validation" do
      user = build :user, email: "UPCASE@GMAIL.COM"
      expect(user.email).to eql "UPCASE@GMAIL.COM"
      user.valid?
      expect(user.email).to eql "upcase@gmail.com"
    end
  end

  describe "password" do
    it "is required" do
      user = build :user, password: ""
      expect(user.valid?).to be_falsey
      expect(user.errors.keys).to include :password
    end

    it "must be confirmed" do
      user = build :user, password_confirmation: ""
      expect(user.valid?).to be_falsey
      expect(user.errors.keys).to include :password_confirmation

      user.password_confirmation = user.password
      expect(user.valid?).to be_truthy
    end

    it "must have at least one number and at least one non-alphanumeric character" do
      user = build :user, password: "password"
      expect(user.valid?).to be_falsey
      expect(user.errors.keys).to include :password

      user.password = user.password_confirmation = "password 1"
      expect(user.valid?).to be_truthy
    end

    it "must be at least 8 characters in length" do
      user = build :user, password: "pass 1"
      expect(user.valid?).to be_falsey
      expect(user.errors.keys).to include :password

      user.password = user.password_confirmation = "passwd 1"
      expect(user.valid?).to be_truthy
    end

    it "must be at most 20 characters in length" do
      user = build :user, password: "this is too long by 13 characters"
      expect(user.valid?).to be_falsey
      expect(user.errors.keys).to include :password

      user.password = user.password_confirmation = "20 characters passes"
      expect(user.valid?).to be_truthy
    end
  end

  describe "generate_password" do
    it "returns a string" do
      expect(User.generate_password).to be_a String
    end

    it "defaults to a length of 8 characters" do
      expect(User.generate_password.length).to eql 8
    end

    it "can generate a longer string" do
      expect(User.generate_password(16).length).to eql 16
    end

    it "always returns a valid password" do
      user = build :user
      99.times do
        user.password = user.password_confirmation = User.generate_password
        expect(user.valid?).to be_truthy
      end
    end
  end

  it "can find users that are drivers for a given provider" do
    driver_1 = create :driver
    driver_2 = create :driver
    drivers = User.drivers driver_1.provider
    expect(drivers).to include driver_1.user
    expect(drivers).not_to include driver_2.user
  end

  it "can update a users password with a valid set of params" do
    user = create :user, password: "password 1"
    params = {current_password: "password 1", password_confirmation: "new password 1"}
    expect(user.update_password(params)).to be_falsey
    expect(user.errors.keys).to include :password

    expect {
      expect(user.update_password(params.merge({password: "new password 1"}))).to be_truthy
    }.to change { user.reload.encrypted_password }
  end

  describe "password_archivable" do
    before do
      Devise.password_archiving_count = 1
    end

    after do
      Devise.password_archiving_count = ApplicationSetting.defaults['devise.password_archiving_count']
    end

    it "does not allow a user to reuse x number of previous passwords" do
      # With an archive count of 1, changing the password twice results in 
      # password 1 being stored in the archive table. Changing it a 3rd 
      # time results in password 2 being added and password 1 being dropped, 
      # and thus able to be used again after 2 changes.

      passwords = ["Password 1", "Password 2", "Password 3"]
      user = create :user, password: passwords[0]

      # Cannot change it to the password currently set
      expect(user.update_password({current_password: passwords[0], password: passwords[0], password_confirmation: passwords[0]})).to be_falsey
      expect(user.errors.keys).to include :password

      # Change to second password, first password is added to archive table
      expect(user.update_password({current_password: passwords[0], password: passwords[1], password_confirmation: passwords[1]})).to be_truthy

      # Cannot change it to the first password
      expect(user.update_password({current_password: passwords[1], password: passwords[0], password_confirmation: passwords[0]})).to be_falsey
      expect(user.errors.keys).to include :password

      # Cannot change it to the second (current) password
      expect(user.update_password({current_password: passwords[1], password: passwords[1], password_confirmation: passwords[1]})).to be_falsey
      expect(user.errors.keys).to include :password

      # Change to third password, second password is added to archive table, 
      # first password is dropped
      expect(user.update_password({current_password: passwords[1], password: passwords[2], password_confirmation: passwords[2]})).to be_truthy
      
      # Can now reuse first password
      expect(user.update_password({current_password: passwords[2], password: passwords[0], password_confirmation: passwords[0]})).to be_truthy
    end
  end
  
  describe "account_expireable" do
    it "locks the user when an expiration date is present" do
      user = create :user
      expect(user.active_for_authentication?).to be_truthy

      user.update_attribute :expires_at, 1.hour.from_now
      expect(user.active_for_authentication?).to be_truthy

      user.update_attribute :expires_at, 1.hour.ago
      expect(user.active_for_authentication?).to be_falsey
    end
  end
end
