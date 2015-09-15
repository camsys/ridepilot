# These settings are stored in the `settings` table in the
# database, but are also cached in tmp/cache. You can destroy
# them all using `ApplicationSetting.delete_all`, but you'll
# also want to `rake tmp:clear` to get rid of the cached values
class ApplicationSetting < RailsSettings::CachedSettings
  def self.update_settings(params)
    transaction do
      self['devise.password_archiving_count'] = params['devise.password_archiving_count'].to_i if params.has_key? "devise.password_archiving_count"

      if params.has_key? "devise.expire_password_after"
        expire_password_after = (params['devise.expire_password_after'] || 0).to_i
        # false means password_expirable is disabled
        self['devise.expire_password_after'] = (expire_password_after == 0) ? false : expire_password_after.days
      end

      return true
    end

    return false
  end
  
  def self.apply!
    Devise.expire_password_after    = self.all['devise.expire_password_after']
    Devise.password_archiving_count = self.all['devise.password_archiving_count']
    return true
  end
end
