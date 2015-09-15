class AddressUploadWorker
  include Sidekiq::Worker

  def perform(filename, provider_id)
    Rails.logger.info "AddressUploadWorker#perform, url=#{filename}"
    provider = Provider.find_by_id(provider_id)
    begin
      Address.load_addresses(filename, provider)
    rescue Exception => ex
      puts ex.message
    end
    
    provider.address_upload_flag.uploaded! if provider
  end
end
