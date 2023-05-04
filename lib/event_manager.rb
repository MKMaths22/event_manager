require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'american_date'

def clean_phone_number(number)
  numbers_array = number.to_s.scan(/[0-9]/)
  return rejoined(numbers_array) if numbers_array.size == 10 || (numbers_array[0] = 1 && numbers_array.size == 11)
  '000-000-0000'
end

def rejoined(my_array)
    # makes the last 10 elements of the array into a standard phone number format abc-def-ghij 
    "#{my_array.slice(-10,3).join('')}-#{my_array.slice(-7,3).join('')}-#{my_array.slice(-4,4).join('')}"
end

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)  
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw' 
  
  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)

  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end
  
puts 'EventManager Initialized'

contents = CSV.open(
                   'event_attendees.csv',
                   headers: true,
                   header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours_of_registration = Array.new(24, 0)

days_of_week_registration = Array.new(7, 0)

contents.each do |row|
  id = row[0]
  
  name = row[:first_name]
    
  zipcode = clean_zipcode(row[:zipcode])

  homephone = clean_phone_number(row[:homephone])

  parsed = Date._parse(row[:regdate])

  registration_date = Date.new(parsed[:year], parsed[:mon], parsed[:mday])

  registration_day_of_week = registration_date.wday

  days_of_week_registration[registration_day_of_week] += 1
  
  registration_hour = parsed[:hour]

  legislators = legislators_by_zipcode(zipcode)
  
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  hours_of_registration[registration_hour] += 1
  
end

def find_peak_times(array)
    peak_times = []
    most_people_in_one_time = array.max()
    array.each_with_index do |people,time|
        peak_times.push(time.to_s) if people == most_people_in_one_time
    end
    p peak_times
end

def name_the_day(num_string)
    case num_string
    when '0' then 'Sunday'
    when '1' then 'Monday'
    when '2' then 'Tuesday'
    when '3' then 'Wednesday' 
    when '4' then 'Thursday'
    when '5' then 'Friday'
    when '6' then 'Saturday'
    else
        'Day not recognised'
    end
end

puts "The peak hour(s) people registered were #{find_peak_times(hours_of_registration).join(', ')}"



puts "The most common day(s) people registered were #{(find_peak_times(days_of_week_registration)).map{ |day| name_the_day(day)}.join(', ')}" 






