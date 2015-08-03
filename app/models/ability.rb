class Ability
  include CanCan::Ability

  def initialize(user)
    can_manage_all = false

    can :read, Mobility
    can :read, TripPurpose
    can :read, TripResult
    can :read, ServiceLevel
    can :read, Region

    for role in user.roles
      if role.system_admin?
        can_manage_all = true
        can :manage, :all 
        break
      end
    end
    
    unless can_manage_all
      for role in user.roles
        if role.editor?
          action = :manage
        else
          action = :read
        end
        can action, Provider, :id => role.provider.id
        cannot :create, Provider
      end
    end

    provider = user.current_provider
    role = Role.where("provider_id = ? and user_id = ?", provider.id, user.id).first
    if not role
      return
    end
    if role.editor?
      action = :manage
    else
      action = [:read, :search]
    end

    can :read, FundingSource, {:providers => {:id => provider.id}}      
    can action, Address, :provider_id => provider.id
    can action, Customer, :provider_id => provider.id
    can action, DevicePool, :provider_id => provider.id if provider.dispatch?
    can action, Driver, :provider_id => provider.id
    can action, Monthly, :provider_id => provider.id
    can action, ProviderEthnicity, :provider_id => provider.id
    can action, RepeatingTrip, :provider_id => provider.id
    can action, Run, :provider_id => provider.id if provider.scheduling?
    can action, Trip, :provider_id => provider.id if provider.scheduling?
    can action, Vehicle, :provider_id => provider.id
    can action, VehicleMaintenanceEvent, :provider_id => provider.id
    can :manage, LookupTable if role.admin?
    can :manage, ApplicationSetting if role.admin?
    can :load, Address if role.admin?
        
    can action, DevicePoolDriver do |device_pool_driver|
      device_pool_driver.provider_id == provider.id
    end
    
    can :manage, DevicePoolDriver do |device_pool_driver|
      device_pool_driver.driver_id == user.driver.id if user.driver
    end

    can :manage, DriverHistory do |driver_history|
      role.admin? and driver_history.driver.provider_id == provider.id
    end
    
    can :manage, DriverCompliance do |driver_compliance|
      role.admin? and driver_compliance.driver.provider_id == provider.id
    end
    
    can action, Document do |document|
      document.documentable.provider_id == provider.id
    end
    
    if role.admin?
      can :manage, User, {:roles => {:provider_id => provider.id}}
      can :manage, Translation
    else
      can :read, User, {:roles => {:provider_id => provider.id}}
    end

  end
end
