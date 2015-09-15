class Utility
  def parse_datetime(time_param)
    return if !time_param.present? 

    # this is to parse calendar params
    # will be deprecated after new calendar gets in
    if time_param.to_i.to_s == time_param.to_s
      time = Time.at(time_param.to_i)
    else
      time = Date.strptime(time_param, '%d-%b-%Y %a') rescue nil
    end

    time.to_date.in_time_zone if time
  end
end