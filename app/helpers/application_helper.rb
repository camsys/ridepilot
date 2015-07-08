module ApplicationHelper
  
  def show_dispatch?
    current_user && current_user.current_provider && current_user.current_provider.dispatch?
  end
  
  def show_scheduling?
    current_user && current_user.current_provider.scheduling?
  end
  
  def new_device_pool_members_options(members)
    options_for_select [["",""]] + members.map { |d| [d.name, d.id] }
  end
  
  def display_trip_result(trip_result)
    TRIP_RESULT_CODES[trip_result] || "Pending"
  end
  
  def format_time_for_listing(time)
    time.strftime('%l:%M%P')
  end

  def format_time_for_listing_day(time)
    time.strftime('%A, %v') 
  end
  
  def format_date_for_daily_manifest(date)
    date.strftime('%A, %v')
  end
  
  def delete_trippable_link(trippable)
    if can? :destroy, trippable
      link_to trippable.trips.present? ? translate_helper("duplicate") : translate_helper("delete"), trippable, :class => 'delete'
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
end
