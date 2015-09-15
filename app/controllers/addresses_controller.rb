require 'open-uri'

class AddressesController < ApplicationController
  load_resource :only => [:edit, :update, :destroy]
  authorize_resource

  def autocomplete
    term = params['term'].downcase.strip

    #clean up address
    term.gsub!(' apt ', ' #')
    term.gsub!(' apartment ', ' #')
    term.gsub!(' suite ', ' #')

    term.gsub!(' n ', ' north ')
    term.gsub!(' ne ', ' northeast ')
    term.gsub!(' e ', ' east ')
    term.gsub!(' se ', ' southeast ')
    term.gsub!(' s ', ' south ')
    term.gsub!(' sw ', ' southwest ')
    term.gsub!(' w ', ' west ')
    term.gsub!(' nw ', ' northwest ')

    term.gsub!(' ave,', 'avenue,')
    term.gsub!(' dr,', 'drive,')
    term.gsub!(' st,', 'street,')
    term.gsub!(' blvd,', 'boulevard,')
    term.gsub!(' pkwy,', 'parkway,')

    #three ways to match:
    #- name
    #- building name
    #- substring of textified address (split at comma into address,
    #  city/state/zip)

    address, city_state_zip = term.split(",")
    address.strip!
    if city_state_zip
      city_state_zip.strip!
    else
      city_state_zip = ''
    end

    addresses = Address.accessible_by(current_ability).where(["((LOWER(address) like '%' || ? || '%' ) and  (city || ', ' || state || ' ' || zip like ? || '%')) or LOWER(building_name) like '%' || ? || '%' or LOWER(name) like '%' || ? || '%' ", address, city_state_zip, term, term]).where(:provider_id => current_provider_id, :inactive => false)

    if addresses.size > 0

      #there are some existing addresses
      address_json = addresses.map { |address| address.json }

      address_json << Address::NewAddressOption unless request.env["HTTP_REFERER"].try(:match, /addresses\/[0-9]+\/edit/)

      render :json => address_json
    else
      #no existing addresses, try geocoding

      term.gsub!(","," ") #nominatim hates commas

      if term.size < 5 or ! term.match /[a-z]{2}/
        #do not geocode too-short terms
        return render :json => [Address::NewAddressOption]
      end
      url = "http://open.mapquestapi.com/nominatim/v1/search?format=json&addressdetails=1&countrycodes=us&q=" + CGI.escape(term)

      result = OpenURI.open_uri(url).read

      addresses = ActiveSupport::JSON.decode(result)

      #only addresses within one decimal degree of the trimet district
      addresses = addresses.find_all { |address|
        point = RGeo::Geographic.spherical_factory(srid: 4326).point(address['lon'].to_f, address['lat'].to_f)
        Region.count(:conditions => ["name='TriMet' and st_distance(the_geom, ?) <= 1", point]) > 0
      }

      #now, convert addresses to local json format
      address_json = addresses.map { |address|
        # TODO add apt numbers
        address = address['address']
        street_address = '%s %s' % [address['house_number'], address['road']]
        address_obj = Address.new(
                    :name => '',
                    :building_name => '',
                    :address => street_address,
                    :city => address['city'],
                    :state => STATE_NAME_TO_POSTAL_ABBREVIATION[address['state'].upcase],
                    :zip => address['postcode'],
                    :the_geom => RGeo::Geographic.spherical_factory(srid: 4326).point(address['lon'].to_f, address['lat'].to_f),
                    :notes => address['notes']
                    )
        address_obj.json

      }

      address_json << Address::NewAddressOption unless request.env["HTTP_REFERER"].try(:match, /addresses\/[0-9]+\/edit/)

      render :json => address_json
    end
  end

  def edit; end
  
  def create
    
    the_geom       = params[:lat].to_s.size > 0 ? RGeo::Geographic.spherical_factory(srid: 4326).point(params[:lon].to_f, params[:lat].to_f, 4326) : nil
    prefix         = params['prefix'] || ""
    address_params = {}

    # Some kind of faux strong parameters...
    for param in ['name', 'building_name', 'address', 'city', 'state', 'zip', 'phone_number', 'in_district', 'trip_purpose_id', 'notes']
      address_params[param] = params[prefix + "_" + param]
    end

    address_params[:provider_id] = current_provider_id
    address_params[:the_geom]    = the_geom

    if params[:address_id].present?
      address = Address.find(params[:address_id])
      authorize! :edit, address
      address.attributes = address_params
    else
      authorize! :new, Address
      address = Address.new(address_params)
    end

    if address.save
      attrs = address.attributes
      attrs[:label] = address.text.gsub(/\s+/, ' ')
      attrs[:prefix] = prefix
      attrs.merge!('phone_number' => address.phone_number, 'trip_purpose' => address.trip_purpose ) if prefix == "dropoff"
      render :json => attrs.to_json
    else
      errors = address.errors.messages
      errors['prefix'] = prefix
      render :json => errors
    end
  end

  def validate
    
    the_geom       = params[:lat].to_s.size > 0 ? RGeo::Geographic.spherical_factory(srid: 4326).point(params[:lon].to_f, params[:lat].to_f, 4326) : nil
    prefix         = params['prefix'] || ""
    address_params = {}

    # Some kind of faux strong parameters...
    for param in ['name', 'building_name', 'address', 'city', 'state', 'zip', 'phone_number', 'in_district', 'trip_purpose_id', 'notes']
      address_params[param] = params[prefix + "_" + param]
    end

    address_params[:provider_id] = current_provider_id
    address_params[:the_geom]    = the_geom

    if params[:address_id].present?
      address = Address.find(params[:address_id])
      address.attributes = address_params
    else
      address = Address.new(address_params)
    end

    if address.valid?
      render :json => {
        success: true,
        prefix: prefix,
        address_text: address.address_text,
        attributes: address.attributes
      }
    else
      errors = address.errors.messages
      errors[:prefix] = prefix
      render :json => errors
    end
  end

  def search
    @term      = params[:name].downcase
    @provider  = Provider.find params[:provider_id]
    @addresses = Address.accessible_by(current_ability).for_provider(@provider).order(:address, :name).search_for_term(@term)

    respond_to do |format|
      format.json { render :text => render_to_string(:partial => "results.html") }
    end
  end

  def update

    if @address.update_attributes address_params
      flash.now[:notice] = "Address '#{@address.name}' was successfully updated"
      redirect_to provider_path(@address.provider)
    else
      render :action => :edit
    end
  end

  def destroy
    if @address.trips.present?
      if new_address = @address.replace_with!(params[:address_id])
        redirect_to new_address.provider, :notice => "#Address was successfully replaced with #{new_address.name}."
      else
        redirect_to edit_address_path(@address), :notice => "#{@address.name} can't be deleted without associating trips with another address."
      end
    else
      @address.destroy
      redirect_to current_provider, :notice => "#{@address.name} was successfully deleted."
    end
  end

  def check_loading_status
    status = {
      is_loading: current_provider.address_upload_flag.is_loading 
    }

    status[:summary] = TranslationEngine.translate_text(:address_file_uploaded) if !status[:is_loading]

    render json: status
  end

  def upload
    error_msgs = []

    if !can?(:load, Address)
      error_msgs << TranslationEngine.translate_text(:not_authorized)
    else
      address_file = params[:address][:file] if params[:address]
      
      if !address_file.nil?
        if File.extname(address_file.original_filename) != '.csv'
          error_msgs << TranslationEngine.translate_text(:address_file_should_be_csv)
        elsif current_provider.address_upload_flag.is_loading
          error_msgs << TranslationEngine.translate_text(:address_file_being_uploading)
        else
          begin
            # Make an object in your bucket for your upload
            s3_file = S3_BUCKET.object("/provider_addresses/" + address_file.original_filename)
            # Upload the file
            s3_file.put(body: address_file, acl: 'public-read')

            AddressUploadWorker.perform_async(s3_file.public_url, current_provider.id) #sidekiq needs to run
          rescue Exception => ex
            current_provider.address_upload_flag.uploaded!
            error_msgs << ex.message
          end
        end
      else
        error_msgs << TranslationEngine.translate_text(:select_address_file_to_upload)
      end
    end

    if error_msgs.size > 0
      full_error_msg = error_msgs.join(' ')
    end

    respond_to do |format|
      format.js
      format.html {redirect_to provider_url(current_provider), alert: full_error_msg }
    end
  end

  private
  
  def address_params
    params.require(:address).permit(:name, :building_name, :address, :city, :state, :zip, :in_district, :provider_id, :phone_number, :inactive, :trip_purpose_id, :notes)
  end
end
