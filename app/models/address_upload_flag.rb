class AddressUploadFlag < ActiveRecord::Base
  belongs_to :provider

  def uploaded!
    update(is_loading: false)
  end

  def uploading!
    update(is_loading: true)
  end
end
