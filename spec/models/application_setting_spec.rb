require "rails_helper"

RSpec.describe ApplicationSetting do
  after do
    ApplicationSetting.update_settings ApplicationSetting.defaults
    ApplicationSetting.apply!
  end
  
  describe "class methods" do
    describe "::update_settings" do
      it "should update only known params" do
        ApplicationSetting.update_settings({'foo' => "asdf"})

        assert_nil ApplicationSetting['foo']
      end

      it "should transform devise.expire_password_after to days when > 0" do
        ApplicationSetting.update_settings({'devise.expire_password_after' => 3})

        assert_equal 3.days, ApplicationSetting['devise.expire_password_after']
      end

      it "should set devise.expire_password_after to false when 0 is specified" do
        ApplicationSetting.update_settings({'devise.expire_password_after' => 0})

        assert_equal false, ApplicationSetting['devise.expire_password_after']
      end

      it "should not change unspecified settings" do
        ApplicationSetting['devise.password_archiving_count'] = 3

        ApplicationSetting.update_settings({'devise.expire_password_after' => 3})

        assert_equal 3, ApplicationSetting['devise.password_archiving_count']
      end
    end

    describe "::apply!" do
      it "should apply all currently saved settings to the application" do
        Devise.expire_password_after    = 99
        Devise.password_archiving_count = 99

        ApplicationSetting['devise.expire_password_after']    = 1
        ApplicationSetting['devise.password_archiving_count'] = 2
        
        ApplicationSetting.apply!

        assert_equal 1, Devise.expire_password_after
        assert_equal 2, Devise.password_archiving_count
      end
    end
  end
end
