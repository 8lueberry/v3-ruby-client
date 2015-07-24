require 'zumata_v3'

# API_KEY = <API KEY>
# API_URL = <API URL>

API_KEY = "XXXX1234"
API_URL = "http://localhost:3001"

#####################
# Initialize Client
#####################

ZumataV3.configure do |config|
  config.api_url = API_URL
  config.api_key = API_KEY
end

@client = ZumataV3::HotelClient.new


#####################
# Search package by destination id
#####################

status = "in-progress"

search = {
  :destination_id => "f75a8cff-c26e-4603-7b45-1b0f8a5aa100",
  :check_in_date => "2015-09-09",
  :check_out_date => "2015-09-10",
  :room_count => 1,
  :adult_count => 2
}

config = {
  :pricing => {
    :fixed_tolerance => 1
  }
}

guest = {
  :salutation => "Mr.",
  :first_name => "Charlie",
  :last_name => "Smith",
  :email => "charlie.smith@zumata.com",
  :city => "Montreal",
  :state => "Quebec",
  :street => "123 Outtamy way",
  :postal_code => "H3H0H0",
  :country => "Canada",
  :room_remarks => "3 carpets please",
  :nationality => "Canadian",
  :contact_no => "+1 514 555-1234",
}

# Keep searching until the api returned a non-empty results
while status == "in-progress"
  result = @client.search_by_destination_id search[:destination_id], {
            check_in_date: search[:check_in_date],
            check_out_date: search[:check_out_date]}

  output = JSON.parse(result.body)
  status = "complete" if output["results"].first != nil || output["status"] == "complete"
  sleep 10 unless status != "in-progress"
end

if output["results"].first == nil
  puts "no results"
  exit
end

package = output["results"].first[1][0]


#####################
# Pre-book a package
#####################

result = @client.prebook search, package, config
output = JSON.parse(result.body)


#####################
# Get pre-book information by pre-book id
#####################

pre_book_id = output["pre_book_id"]
result = @client.get_prebook pre_book_id
output = JSON.parse(result.body)


#####################
# Book a package (with credit) by using pre-book id
#####################

result = @client.book_by_credit guest, pre_book_id, {affiliate_key: "testing"}
output = JSON.parse(result.body)
reference = output["reference"]

result = @client.get_book reference
output = JSON.parse(result.body)

puts reference


#####################
# Get booking information by reference
#####################

status = "IP"
while status == "IP"
  result = @client.get_book reference
  output = JSON.parse(result.body)
  status = output["status"]
  puts output["status"]
  sleep 10 if status == "IP"
end

if output["status"] != "CF"
  puts "booking not confirmed, exiting..."
  exit
end

#####################
# Cancel booking by reference
#####################

result = @client.cancel reference
output = JSON.parse(result.body)
puts output
