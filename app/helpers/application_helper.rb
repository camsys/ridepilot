module ApplicationHelper  
  def current_provider
    current_user.try(:current_provider)
  end

  def current_provider_id
    current_provider.try(:id)
  end

  def show_dispatch?
    current_user && current_provider && current_provider.dispatch?
  end
  
  def show_scheduling?
    current_user && current_provider.scheduling?
  end

  def can_edit_role?(role)
    false if !current_user.present?

    is_allowed = can? :edit, role
    is_allowed = current_user.super_admin? if is_allowed && role.system_admin?

    is_allowed
  end

  def is_admin_or_system_admin?
    current_user.present? && (current_user.admin? || current_user.super_admin?)
  end
  
  def new_device_pool_members_options(members)
    options_for_select [["",""]] + members.map { |d| [d.name, d.id] }
  end
  
  def display_trip_result(trip_result)
    trip_result.try(:name) || "Pending"
  end

  def format_full_datetime(time)
    time.strftime "%l:%M%P %a %d-%b-%Y" if time
  end
  
  def format_time_for_listing(time)
    time.strftime('%l:%M%P') if time
  end

  def format_time_for_listing_day(time)
    time.strftime('%d-%b-%Y %a') if time
  end

  def format_time_as_title_for_listing_day(time)
    time.strftime('%b %d, %Y') if time
  end
  
  def format_date_for_daily_manifest(date)
    date.strftime('%A, %v') if date
  end
  
  def delete_trippable_link(trippable)
    if can? :destroy, trippable
      link_to trippable.trips.present? ? translate_helper("merge") : translate_helper("delete"), trippable, :class => 'delete'
    end
  end
  
  def can_delete?(trippable)
    trippable.trips.blank? && can?( :destroy, trippable )
  end
  
  def format_newlines(text)
    return text.gsub("\n", "<br/>")
  end

  def bodytag_class
    a = controller.controller_name.underscore
    b = controller.action_name.underscore
    "#{a} #{b}".gsub(/_/, '-')
  end

  def collect_weekdays(schedule)
    weekdays = []
    if schedule.monday
      weekdays.push :monday
    end
    if schedule.tuesday
      weekdays.push :tuesday
    end
    if schedule.wednesday
      weekdays.push :wednesday
    end
    if schedule.thursday
      weekdays.push :thursday
    end
    if schedule.friday
      weekdays.push :friday
    end
    if schedule.saturday
      weekdays.push :saturday
    end
    if schedule.sunday
      weekdays.push :sunday
    end
    return weekdays
  end

  def weekday_abbrev(weekday)
    weekday_abbrevs = {
      :monday => 'M',
      :tuesday => 'T',
      :wednesday => 'W',
      :thursday => 'R',
      :friday => 'F',
      :saturday => 'S',
      :sunday => 'U'
    }

    return weekday_abbrevs[weekday]
  end

  def is_add_user_allowed?(user)
    user.present? && ( user.admin? || user.super_admin?)
  end

  def add_tooltip(key)
    if TranslationEngine.translation_exists?(key)
      html = '<i class="fa fa-question-circle fa-2x pull-right label-help" style="margin-top:-4px;" title data-content="'
      html << TranslationEngine.translate_text(key.to_sym)
      html << '" aria-label="'
      html << TranslationEngine.translate_text(key.to_sym)
      html << '" tabindex="0"></i>'
      return html.html_safe
    end
  end

  def reimbursement_cost_for_trips(provider, trips)
    number_to_currency ReimbursementRateCalculator.new(provider).total_reimbursement_due_for_trips(trips)
  end
end
