class CustomersController < ApplicationController
  load_and_authorize_resource :except=>[:autocomplete, :found, :edit, :show, :update]

  def autocomplete
    customers = Customer.for_provider(current_provider_id).by_term( params['term'].downcase, 10 ).accessible_by(current_ability)
    
    render :json => customers.map { |customer| customer.as_autocomplete }
  end

  def found
    if params[:customer_id].blank?
      redirect_to search_customers_path( :term => params[:customer_name] )
    elsif params[:commit].downcase.starts_with? "new trip"
      redirect_to new_trip_path :customer_id=>params[:customer_id]
    else
      redirect_to customer_path params[:customer_id]
    end
  end

  def index
    # only active customers
    @show_inactivated_date = false
    @customers = Customer.for_provider(current_provider_id).where(:inactivated_date => nil)
    @customers = @customers.by_letter(params[:letter]) if params[:letter].present?
    
    respond_to do |format|
      format.html { @customers = @customers.paginate :page => params[:page], :per_page => PER_PAGE }
      format.xml  { render :xml => @customers }
    end
  end
  
  def all
    @show_inactivated_date = true
    @customers = Customer.for_provider(current_provider_id).accessible_by(current_ability)
    @customers = @customers.paginate :page => params[:page], :per_page => PER_PAGE
    render :action => :index
  end

  def search
    @customers = Customer.for_provider(current_provider_id).by_term(params[:term].downcase).
      accessible_by(current_ability).
      paginate(:page => params[:page], :per_page => PER_PAGE)
      
    render :action => :index
  end

  def show
    @customer = Customer.find(params[:id])

    # default scope is pickup time ascending, so reverse
    if !@customer.authorized_for_provider(current_provider.id)
      authorize! :show, @customer 
    else
      @read_only_customer = false
      @read_only_customer = true if @customer.provider_id != current_provider.id
    end

    prep_edit

    @trips    = @customer.trips.reorder('pickup_time desc').paginate :page => params[:page], :per_page => PER_PAGE

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @customer }
    end
  end

  def new
    @customer = Customer.new name_options
    @customer.provider = current_provider
    #@customer.address ||= @customer.build_address :provider => current_provider
    prep_edit

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @customer }
    end
  end

  def edit
    @customer = Customer.find(params[:id])
    authorize! :edit, @customer if !@customer.authorized_for_provider(current_provider.id)
    prep_edit
  end

  def create
    @customer = Customer.new customer_params
    @customer.provider = current_provider
    @customer.activated_date = Date.today
    edit_addresses @customer

    if params[:ignore_dups] != "1"
      #check for duplicates
      #similar-sounding first/last names and (no or matching) middle initial

      first_name = @customer.first_name
      middle_initial = @customer.middle_initial
      last_name = @customer.last_name
      dup_customers = Customer.accessible_by(current_ability).where([
"(middle_initial = ? or middle_initial = '' or ? = '') and 

(dmetaphone(last_name) = dmetaphone(?) or
 dmetaphone(last_name) = dmetaphone_alt(?) or 
 dmetaphone_alt(last_name) = dmetaphone(?) or 
 dmetaphone_alt(last_name) = dmetaphone_alt(?)) and

(dmetaphone_alt(first_name) = dmetaphone_alt(?) or
 dmetaphone_alt(first_name) = dmetaphone(?) or
 dmetaphone(first_name) = dmetaphone(?)  or
 dmetaphone(first_name) = dmetaphone_alt(?)) or
(email = ? and email !=  '' and email is not null and ? != '')
", 
middle_initial, middle_initial, 
last_name, last_name, last_name, last_name, 
first_name, first_name, first_name, first_name,
@customer.email, @customer.email]).limit(1)

      if dup_customers.size > 0
        dup = dup_customers[0]
        flash.now[:alert] = "There is already a customer with a similar name or the same email address: <a href=\"#{url_for :action=>:show, :id=>dup.id}\">#{dup.name}</a> (dob #{dup.birth_date}).  If this is truly a different customer, check the 'ignore duplicates' box to continue creating this customer.".html_safe
        @dup = true
        prep_edit
        return render :action=>"new"
      end
    end

    providers = []
    params[:customer][:authorized_provider_ids].each do |authorized_provider_id|
      providers.push(Provider.find(authorized_provider_id)) if authorized_provider_id.present?
    end

    @customer.authorized_providers = (providers << @customer.provider).uniq

    respond_to do |format|
      if @customer.is_all_valid?(current_provider_id) && @customer.save
        format.html { redirect_to(@customer, :notice => 'Customer was successfully created.') }
        format.xml  { render :xml => @customer, :status => :created, :location => @customer }
      else
        prep_edit
        format.html { render :action => "new" }
        format.xml  { render :xml => @customer.errors, :status => :unprocessable_entity }
      end
    end
  end

  def inactivate
    @customer = Customer.find(params[:customer_id])
    authorize! :edit, @customer

    @customer.inactivated_date = Date.today
    @customer.inactivated_reason = params[:customer][:inactivated_reason]
    @customer.save
    redirect_to :action => :index
  end

  def update
    @customer = Customer.find(params[:id])

    authorize! :update, @customer if !@customer.authorized_for_provider(current_provider.id)

    @customer.assign_attributes customer_params
    edit_addresses @customer

    #save address changes
    if address_attributes_param && address_attributes_param[:id].present?
      address = Address.find(address_attributes_param[:id])
      address.assign_attributes(address_params)
    end

    providers = []
    params[:customer][:authorized_provider_ids].each do |authorized_provider_id|
      providers.push(Provider.find(authorized_provider_id)) if authorized_provider_id.present?
    end
    @customer.authorized_providers = (providers << @customer.provider).uniq
    
    
    
    respond_to do |format|
      if @customer.is_all_valid?(current_provider_id) && @customer.save
        format.html { redirect_to(@customer, :notice => 'Customer was successfully updated.') }
        format.xml  { head :ok }
      else
        prep_edit
        format.html { render :action => "edit" }
        format.xml  { render :xml => @customer.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    if @customer.trips.present?
      if new_customer = @customer.replace_with!(params[:customer_id])
        redirect_to new_customer, :notice => "#{@customer.name} was successfully deleted."
      else
        redirect_to @customer, :notice => "#{@customer.name} can't be deleted without associating trips with another customer."
      end
    else
      @customer.destroy
      redirect_to customers_url, :notice => "#{@customer.name} was successfully deleted."
    end
  end
  
  private
  
  def customer_params
    params.require(:customer).permit(
      :gender,
      :ada_eligible,
      :birth_date,
      :default_funding_source_id,
      :service_level_id,
      :email,
      :emergency_contact_notes,
      :ethnicity,
      :first_name,
      :group,
      :last_name,
      :medicaid_eligible,
      :middle_initial,
      :mobility_id,
      :mobility_notes,
      :phone_number_1,
      :phone_number_2,
      :prime_number,
      :private_notes,
      :public_notes,
      :authorized_provider_ids,
      :is_elderly,
      :address_attributes => [
        :address,
        :building_name,
        :city,
        :name,
        :provider_id,
        :state,
        :zip,
        :notes
      ],
    )
  end

  def address_attributes_param
    params[:customer][:address_attributes]
  end

  def address_params
    address_attributes_param.permit(
      :name, :building_name, :address, 
      :city, :state, :zip, :in_district, 
      :provider_id, :phone_number, :inactive, 
      :trip_purpose_id, :notes) if address_attributes_param
  end

  def name_options
    if params[:customer_name]
      parts = params[:customer_name].split " "
      atts  = { :first_name => parts.first }

      case parts.length
      when 2
        atts[:last_name]      = parts.last
      else
        atts[:middle_initial] = parts[1]
        atts[:last_name]      = parts[2, parts.length - 2].join " "
      end if parts.length > 1

      atts
    end || {}
  end
  
  def prep_edit
    @mobilities = Mobility.all
    @ethnicity_names = (current_provider.ethnicities.collect(&:name) + [@customer.ethnicity]).compact.sort.uniq
    @funding_sources = FundingSource.by_provider(current_provider)
    @service_levels = ServiceLevel.pluck(:name, :id)
  end

  def edit_addresses(customer)
    if params[:addresses]
      addresses = JSON.parse(params[:addresses])
      customer.edit_addresses addresses, params[:mailing_address_index].to_i || 0
    end
  end

end
