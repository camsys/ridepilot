class Role < ActiveRecord::Base
  acts_as_paranoid # soft delete
  
  belongs_to :user
  belongs_to :provider
  validates_uniqueness_of :user_id, :scope => :provider_id

  # constants for role display names
  SYSTEM_ADMIN_NAME = 'System Admin'
  ADMIN_NAME = 'Admin'
  EDITOR_NAME = 'Editor'
  USER_NAME = 'User'
  # constants for role levels
  SYSTEM_ADMIN_LEVEL = 200
  ADMIN_LEVEL = 100
  EDITOR_LEVEL = 50
  USER_LEVEL = 0

  ROLE_ARRAY = [
    [SYSTEM_ADMIN_NAME, SYSTEM_ADMIN_LEVEL], 
    [ADMIN_NAME, ADMIN_LEVEL],
    [EDITOR_NAME, EDITOR_LEVEL],
    [USER_NAME, USER_LEVEL]
  ]

  scope :system_admins, -> { where(level: SYSTEM_ADMIN_LEVEL) }
  scope :admins, -> { where(level: ADMIN_LEVEL) }
  scope :editors, -> { where(level: EDITOR_LEVEL) }

  # TODO: need to discuss with Chris on using >= instead of == here
  def system_admin?
    level >= SYSTEM_ADMIN_LEVEL
  end

  def admin?
    level >= ADMIN_LEVEL
  end

  def editor?
    level >= EDITOR_LEVEL
  end

  def user?
    level < EDITOR_LEVEL
  end

  def name
    if system_admin?
      SYSTEM_ADMIN_NAME
    elsif admin?
      ADMIN_NAME
    elsif editor?
      EDITOR_NAME
    else
      USER_NAME
    end
  end

  def self.editable_role_array_by_user(a_user)
    return [] if !a_user.present?

    if a_user.super_admin?
      ROLE_ARRAY
    elsif a_user.admin?
      ROLE_ARRAY[1, ROLE_ARRAY.size]
    else
      []
    end
        
  end

end
