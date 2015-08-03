class AddressUploadWorker
  include Sidekiq::Worker

  def perform(filename, provider_id)
    Rails.logger.info "AddressUploadWorker#perform, url=#{filename}"
    provider = Provider.find_by_id(provider_id)
    Address.load_addresses(filename, provider)
    provider.address_upload_flag.uploaded! if provider
  end
end
