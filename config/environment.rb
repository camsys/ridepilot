# Load the Rails application.
require File.expand_path('../application', __FILE__)

Rails.application.routes.default_url_options[:host] = ENV['RIDEPILOT_HOST']

TRIP_RESULT_CODES = {
  "COMP"  => "Complete",    # the trip was (as far as we know) completed
  "NS"    => "No-show",     # the customer did not show up for the trip
  "CANC"  => "Cancelled",   # the trip was cancelled by the customer
  "TD"    => "Turned down", # the provider told the customer that it could not provide the trip
  "UNMET" => "Unmet Need"   # a trip that was outside of the service parameters (too early, too late, too far, etc).
}

TRIP_PURPOSES = ["Life-Sustaining Medical", "Medical", "Nutrition", "Personal/Support Services", "Recreation", "School/Work", "Shopping", "Volunteer Work", "Center"]
TRIP_PURPOSES_KEYS = ["Life-Sustaining Medical", "Medical", "Nutrition", "Personal/Support Services", "Recreation", "School/Work", "Shopping", "Volunteer Work", "Center"]

SERVICE_LEVELS = ["Wheelchair", "Ambulatory"]

TRIP_VERIFICATION_DISPLAY_OPTIONS = ['All Trips','Cab Trips','Not Cab Trips']

BUSINESS_HOURS = {
  :start => 7,
  :end => 18,
}

PER_PAGE = 30

STATE_NAME_TO_POSTAL_ABBREVIATION = {
  "ALABAMA" => "AL",
  "ALASKA" => "AK",
  "AMERICAN SAMOA" => "AS",
  "ARIZONA" => "AZ",
  "ARKANSAS" => "AR",
  "CALIFORNIA" => "CA",
  "COLORADO" => "CO",
  "CONNECTICUT" => "CT",
  "DELAWARE" => "DE",
  "DISTRICT OF COLUMBIA" => "DC",
  "FEDERATED STATES O MICRONESIA" => "FM",
  "FLORIDA" => "FL",
  "GEORGIA" => "GA",
  "GUAM" => "GU",
  "HAWAII" => "HI",
  "IDAHO" => "ID",
  "ILLINOIS" => "IL",
  "INDIANA" => "IN",
  "IOWA" => "IA",
  "KANSAS" => "KS",
  "KENTUCKY" => "KY",
  "LOUISIANA" => "LA",
  "MAINE" => "ME",
  "MARSHALL ISLANDS" => "MH",
  "MARYLAND" => "MD",
  "MASSACHUSETTS" => "MA",
  "MICHIGAN" => "MI",
  "MINNESOTA" => "MN",
  "MISSISSIPPI" => "MS",
  "MISSOURI" => "MO",
  "MONTANA" => "MT",
  "NEBRASKA" => "NE",
  "NEVADA" => "NV",
  "NEW HAMPSHIRE" => "NH",
  "NEW JERSEY" => "NJ",
  "NEW MEXICO" => "NM",
  "NEW YORK" => "NY",
  "NORTH CAROLINA" => "NC",
  "NORTH DAKOTA" => "ND",
  "NORTHERN MARIANA ISLANDS" => "MP",
  "OHIO" => "OH",
  "OKLAHOMA" => "OK",
  "OREGON" => "OR",
  "PALAU" => "PW",
  "PENNSYLVANIA" => "PA",
  "PUERTO RICO" => "PR",
  "RHODE ISLAND" => "RI",
  "SOUTH CAROLINA" => "SC",
  "SOUTH DAKOTA" => "SD",
  "TENNESSEE" => "TN",
  "TEXAS" => "TX",
  "UTAH" => "UT",
  "VERMONT" => "VT",
  "VIRGIN ISLANDS" => "VI",
  "VIRGINIA" => "VA",
  "WASHINGTON" => "WA",
  "WEST VIRGINIA" => "WV",
  "WISCONSIN" => "WI",
  "WYOMING" => "WY"
}

# Initialize the Rails application.
Rails.application.initialize!
