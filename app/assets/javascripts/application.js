// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require bootstrap-sprockets
//= require jquery_ujs
//= require dataTables/jquery.dataTables
//= require jquery-ui
//= require autocomplete-rails
//= require jquery.weekcalendar
//= require jquery-ui-timepicker-addon
//= require dateFormat
//= require jquery.colorPicker
//= require idletimeout
//= require constants
//= require_self

function ISODateFormatToDateObject(str) {
  if(str === null) return null;

  var parts = str.split(' ');
  if(parts.length < 3) return null;

  var dateParts = parts[1].split('-'),
  timeSubParts = parts[2].split(':'),
  timeHours = Number(timeSubParts[0]),
  amPm = parts[3].toUpperCase();

  _date = new Date();
  _date.setFullYear( Number(dateParts[0]), (Number(dateParts[1])-1), Number(dateParts[2]) );
  
  _date.setHours(Number( amPm.slice(0,1) == "P" && timeHours != 12 ? timeHours + 12 : timeHours), Number(timeSubParts[1]), 0, 0);

  return _date;
}

function supports_history_api() {
  return !!(window.history && history.pushState);
}

MS_in_a_minute = 60000;
MS_in_a_day    = 86400000;
MS_in_an_hour  = 3600000;
MS_in_a_week   = 604800000;

// does time fall within the current week ? 
function week_differs (time) {
  var current_start = $("#calendar").data("start-time");
  return !(current_start <= time && time < current_start + MS_in_a_week);
}

// finds start of monday for week of given time, sets calendar start_time
function set_calendar_time(time) {
  var date       = new Date(time);
  var start_time = time - (date.getDay() - 1) * MS_in_a_day - 
    date.getHours() * MS_in_an_hour - 
    date.getMinutes() * MS_in_a_minute - 
    date.getSeconds() * 1000 - 
    date.getMilliseconds() ;
  
  $("#calendar").data("start-time", start_time)
}

$(function() {

  $("tr:odd").addClass("odd");
  
  // delete a customer from the show page
  $("body.customers.show .profile-actions .delete, body.addresses.edit .profile-actions .delete").click( function(event){
    event.preventDefault();

    var link = $(this);
    
    if ( $("#confirm-destroy").length > 0 ) {
      $( "#confirm-destroy" ).dialog({
        resizable: false,
        width: 480,
      	modal: true,
      	title: $("#confirm-destroy").find("legend").text(),
      	buttons: {
      		Confirm: function() {
      			$( this ).find( "form" ).submit();
      		},
      		Cancel: function() {
      			$( this ).dialog( "close" );
      		}
      	}
      });
    } else {
      $( "<div>" ).text("This will be permanently deleted. Are you sure?").dialog({
      	resizable: false,
      	modal: true,
      	buttons: {
      		Confirm: function() {
      		  link.attr("data-method", "delete").click();
      		},
      		Cancel: function() {
      			$( this ).dialog( "close" );
      		}
      	}
      });
    }
  });

  // set default driver for trip based on selected vehicle
  $("body").on("change", "#trip_vehicle_id", function(event){
    $("#trip_driver_id").val( $(this).find("option[value=" + $(this).val() + "]").data("driver-id") );
  });

  // hide middle/last names for group customer
  var updateGroupField = function() {
    if ( $('input#customer_group').is(':checked') ){
      $('li.middlename, li.lastname, li.ethnicity, li.birth_date').hide();
      $('li.firstname label').html("Group Name:");
    } else {
      $('li.middlename, li.lastname, li.ethnicity, li.birth_date').show();
      $('li.firstname label').html("First Name:");
    }
  };
  updateGroupField();
  $('input#customer_group').click(updateGroupField);

  $('#new_monthly #monthly_start_date, #new_monthly #monthly_end_date, input.datepicker').datepicker({
		dateFormat: 'yy-mm-dd'    		
  });
  
  // when trip pickup time is changed, update appointment time and displayed week
  $("body").on('change', '#trip_pickup_time', function() {
    var pickupTimeDate      = ISODateFormatToDateObject( $('#trip_pickup_time').attr("value") );
    var appointmentTimeDate = new Date(pickupTimeDate.getTime() + (1000 * 60 * 30));

    $('#trip_appointment_time').attr( "value", appointmentTimeDate.format("ddd yyyy-mm-dd hh:MM tt"));
    
    if ( week_differs(appointmentTimeDate.getTime()) ) {
      $("#calendar").weekCalendar("gotoWeek", appointmentTimeDate.getTime());
      set_calendar_time(appointmentTimeDate.getTime());
    }    
  });
  
  // needs to be -1 for field nulling
  $("#trip_vehicle_id option:contains(cab)").attr("value", "-1")
  
  $("body").on('change', "#trip_run_id", function(){
    $("#trip_vehicle_id").val("");
    $("#trip_driver_id").val("");
  });
  
  $("body").on("change", "#trip_vehicle_id, #trip_driver_id", function(){
    $("#trip_run_id").val("");
  });
  
  $("body").on("change", "#vehicle_filter #vehicle_id", function(){
    var form = $(this).parents("form");
    $.get(form.attr("action"), form.serialize() + "&" + window.location.search.replace(/^\?/,""), function(data) {
      $("#calendar").weekCalendar("clear");
      $.each( data.events, function(i, e){
        $("#calendar").weekCalendar("updateEvent", e);
      } );
      var table = $("#calendar").next("table");
      table.find("tr.trip").remove();
      table.find("tr.day").remove();
      $.each(data.rows, function(i, row){
        table.append(row);
      })
      $("tr:odd").addClass("odd");
    }, "json");
  });
  
  $('#new_trip #customer_name').bind('railsAutocomplete.select', function(event, data){ 
    if ($("#trip_group").val() == "true") {
      $("li.passengers").hide();
      $("li.group_size").show();
    } else {
      $("li.passengers").show();
      $("li.group_size").hide();
    }
  });
  
  $('.new_trip #customer_name, .edit_trip #customer_name').bind('railsAutocomplete.select', function(event, data){ 
    if (parseInt(data.address_id) > 0)
      autocompleted(data.address_data, 'pickup');
  });
  
  $("body").on("click", "#new_customer[data-path]", function(e) {
    window.location = $(this).attr("data-path") + "?customer_name=" + $("#customer_name").val();
  });
    
  function push_index_state(range) {
     if (supports_history_api()) history.pushState({index: range}, "List Runs", window.location.pathname + "?" + $.param(range));
  }

  function load_index_runs(range, push_state) {
    var new_start = new Date(parseInt(range['start']) * 1000);
    var new_end   = new Date(parseInt(range['end']) * 1000);
     
    $.get(window.location.href, range, function(data) {
      $("#runs tr, #cab_trips tr").not(".head").remove();
      $("#runs, #cab_trips").append(data.rows.join(""));
      $(".wc-nav").attr("data-start-time", new_start.getTime());
      $("#start_date").html((new_start.getMonth()+1) + "-" + new_start.getDate() + "-" + new_start.getFullYear());
      $("#end_date").html((new_end.getMonth()+1) + "-" + new_end.getDate() + "-" + new_end.getFullYear());  
      if (push_state) push_index_state(range);
    }, "json");
  }

  window.onpopstate = function(event) {
    if (event.state) {
      if (event.state['index']) {
        load_index_runs(event.state['index'], false);
      } 
    } else {
      new_start = parseInt($(".wc-nav").attr("data-current-week-start"))/1000
      new_end = new Date(new_start * 1000);
      new_end.setDate(new_end.getDate() + 6);
      if (new_start && new_end) {
        range = {start: new_start, end: new_end.getTime()/1000};
        load_index_runs(range, false);
      }
    }
  };
 
  $("body.runs .wc-nav button, body.cab-trips .wc-nav button").click(function(e){
    var current_start, new_start, new_end;
    var target    = $(this);
    var week_nav  = target.parent(".wc-nav");
    
    if (target.hasClass("wc-today")){
      current_start = new Date(parseInt(week_nav.attr("data-current-week-start")));
      new_start     = new Date(current_start.getTime());
      new_end       = new Date(current_start.getTime());
      new_end.setDate(new_end.getDate() + 6);
    } else {
      current_start = new Date(parseInt(week_nav.attr("data-start-time")));
      new_start     = new Date(current_start.getTime());
      new_end       = new Date(current_start.getTime());
      
      if (target.hasClass("wc-prev")) {
        new_start.setDate(new_start.getDate() - 7); 
        new_end.setDate(new_end.getDate() - 1);
      } else {
        new_start.setDate(new_start.getDate() + 7); 
        new_end.setDate(new_end.getDate() + 13);
      }
    }
    range = {start: new_start.getTime()/1000, end: new_end.getTime()/1000};
    load_index_runs(range,true);
    
  });
  
  $("#search_addresses").bind('ajax:complete', function(event, data, xhr, status){
    var form    = $(this);
    var table   = $("#address_results");
    var results = $(data.responseText);
    
    table.find("tr").not("tr:first-child").remove();
    
    if (results[0] && results[0].nodeName.toUpperCase() == "TR")
      table.append(results);
    else
      table.append("<tr><td>There was an error searching</td></tr>");
  });
  
  $("body").on('ajax:complete', ".delete.device_pool_driver", function(event, data, xhr, status){
    $(this).parents("tr").eq(0).hide("slow").remove();
        
    var json = eval('(' + data.responseText + ')');
    
    if (json.device_pool_driver) {
      if (json.device_pool_driver.name.substring(0,8) == "Driver: ") {
        var option = $("<option>").val(json.device_pool_driver.driver_id).text(json.device_pool_driver.name.substring(8));
        $("select.new_device_pool_driver").append(option);
      }
      if (json.device_pool_driver.name.substring(0,9) == "Vehicle: ") {
        var option = $("<option>").val(json.device_pool_driver.driver_id).text(json.device_pool_driver.name.substring(9));
        $("select.new_device_pool_vehicle").append(option);
      }
    }
  });
  
  $("a.add_driver_to_pool").bind("click", function(click){
    var link   = $(this);
    var select = link.prev("select");
    
    $.post( link.attr("href"),
      { device_pool_driver : { driver_id : select.val() } }, 
      function(data) {
        if (data.row) {
          var table = link.parents("td").eq(0).find("table");
          table.find("tr.empty").hide();
          table.append(data.row);
          $("select.new_device_pool_driver option[value=" + select.val() + "]").remove();
          
          link.parent("p").hide().prev("p").show();          
        } else {
          alert("Could not add the selected driver to the device pool. Please try again.");
        }
      }, "json"
    );
    
    click.preventDefault();
  });
  
  $("a.add_vehicle_to_pool").bind("click", function(click){
    var link   = $(this);
    var select = link.prev("select");
    
    $.post( link.attr("href"),
      { device_pool_driver : { vehicle_id : select.val() } }, 
      function(data) {
        if (data.row) {
          var table = link.parents("td").eq(0).find("table");
          table.find("tr.empty").hide();
          table.append(data.row);
          $("select.new_device_pool_vehicle option[value=" + select.val() + "]").remove();
          
          link.parent("p").hide().prev("p").show();          
        } else {
          alert("Could not add the selected vehicle to the device pool. Please try again.");
        }
      }, "json"
    );
    
    click.preventDefault();
  });
  
  $("body").on("click", "a.add_device_pool_driver", function(click){
    var link = $(this);
    link.parent("p").hide().next("p").show();
    
    click.preventDefault();
  });

  $("body").on("click", "a.add_device_pool_vehicle", function(click){
    var link = $(this);
    link.parent("p").hide().next("p").show();
    
    click.preventDefault();
  });

  $('[data-behavior=time-picker]').timepicker({
    ampm: true,
    stepMinute: 15,
    stepHour: 1,
    hourMin: RidePilot.business_hours.start,
    hourMax: RidePilot.business_hours.end,
    hourGrid: 2,
    minuteGrid: 15,
    showOn: "button",
    timeFormat: 'hh:mm TT',
    buttonImage: "../../images/calendar-clock.png",
    buttonImageOnly: true,
    constrainInput: false
  });
});

/* Show the 'title' attribute of a field as a hint. */
function hinted_field(f) {
  if (f.length) {
    var dval = f.attr('title');
    if (dval) {
      if (!f.val().length) {
        f.val(dval);
        f.addClass("hint");
      }
      f.focus(function() {
        if(f.val() == dval) {
          f.val('');
          f.removeClass("hint");
        }
      }).blur(function() {
        if(!f.val().length) {
          f.val(dval);
          f.addClass("hint");
        }
      });
    }
  }
}

/* Display a map region in the given jQuery object. */
function display_region(object, bounds) {
  // Validate bounds
  errors = validate_bounds(bounds);
  if (errors.length > 0)
    return errors;

  // Create map view
  var map = new google.maps.Map(object.get(0), {
    mapTypeId: google.maps.MapTypeId.ROADMAP,
  });
  var nw = new google.maps.LatLng(bounds.north, bounds.west);
  var se = new google.maps.LatLng(bounds.south, bounds.east);
  var bounds = new google.maps.LatLngBounds(nw, se);
  map.fitBounds(bounds);

  rectangle = new google.maps.Rectangle();
  google.maps.event.addListener(map, 'zoom_changed', function() {

    // Get the current bounds, which reflect the bounds before the zoom.
    var rectOptions = {
      strokeColor: "#598FEF",
      strokeOpacity: 1,
      strokeWeight: 2,
      fillColor: "#E5F2FF",
      fillOpacity: 0.3,
      map: map,
      bounds: bounds
    };
    rectangle.setOptions(rectOptions);
  });

  return null;
}

function validate_bounds(bounds) {
  errors = []
  if (bounds.north < bounds.south)
    errors.push('North latitude must be greater than south.');
  if (bounds.east < bounds.west)
    errors.push('East longitude must be greater than west.');
  if (Math.abs(bounds.north) > 90)
    errors.push('North latitude is invalid.');
  if (Math.abs(bounds.west) > 180)
    errors.push('West longitude is invalid.');
  if (Math.abs(bounds.south) > 90)
    errors.push('South latitude is invalid.');
  if (Math.abs(bounds.east) > 180)
    errors.push('East longitude is invalid.');
  return errors;
}

function display_viewport(object, viewport) {
  errors = validate_viewport(viewport);
  if (errors.length > 0)
    return errors;

  // Create map view
  center = new google.maps.LatLng(viewport.center_lat, viewport.center_lng);
  var map = new google.maps.Map(object.get(0), {
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    center:    center,
    zoom:      viewport.zoom
  });

  // Mark the center
  var marker = new google.maps.Marker({
    map: map,
    position: center
  });

  return null;
}

function validate_viewport(viewport) {
  errors = []
  if (Math.abs(viewport.center_lat) > 90)
    errors.push('Center latitude is invalid.')
  if (Math.abs(viewport.center_lng) > 180)
    errors.push('Center longitude is invalid.')
  if (viewport.zoom < 0 || viewport.zoom >= 20)
    errors.push('Zoom must be between 0 and 19.');
  return errors;
}
