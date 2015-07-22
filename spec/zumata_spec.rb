require 'json'
require 'spec_helper'
require './lib/zumata_v3'

describe "ZumataV3::HotelClient configuration" do

  it 'will raise an error if api & url are not provided' do

    expect{
      ZumataV3.configure do |config|
        config.api_url = nil
        config.api_key = nil
      end
      ZumataV3::HotelClient.new
      }.to raise_error(ZumataV3::ClientConfigError)

    expect{
      ZumataV3.configure do |config|
        config.api_url = ENV["ZUMATA_API_URL"]
        config.api_key = nil
      end
      ZumataV3::HotelClient.new
      }.to raise_error(ZumataV3::ClientConfigError)

    expect{
      ZumataV3.configure do |config|
        config.api_url = nil
        config.api_key = ENV["ZUMATA_API_KEY"]
      end
      ZumataV3::HotelClient.new
      }.to raise_error(ZumataV3::ClientConfigError)

  end

end

describe "ZumataV3::HotelClient endpoints" do

  vcr_recorded_check_in_date = (Time.now + 60*60*60*24).strftime("%Y-%m-%d")
  vcr_recorded_check_out_date = (Time.now + 61*60*60*24).strftime("%Y-%m-%d")

  before(:each) do

    raise "Tests require environment variable 'ZUMATA_API_KEY' to be configured" unless ENV["ZUMATA_API_KEY"]

    ZumataV3.configure do |config|
      config.api_url = ENV["ZUMATA_API_URL"]
      config.api_key = ENV["ZUMATA_API_KEY"]
    end

    @client = ZumataV3::HotelClient.new
  end

  describe "search_by_destination_id" do

    it 'returns a successful response if the query is valid', :vcr => { :cassette_name => "search_by_destination_id_done", :record => :new_episodes } do
      # note - when recording the cassette this requires a cached search w/ results to exist
      destination_id = "f75a8cff-c26e-4603-7b45-1b0f8a5aa100" # Singapore
      results = @client.search_by_destination_id destination_id, {check_in_date: vcr_recorded_check_in_date, check_out_date: vcr_recorded_check_out_date}
    	data = JSON.parse(results.body)
      expect(data).to_not be(nil)
    end

    it 'raises an error if invalid inputs are provided', :vcr => { :cassette_name => "search_by_destination_id_fail", :record => :new_episodes } do
      destination_id = "invalid" # Singapore
      expect{
        @client.search_by_destination_id destination_id, {check_in_date: vcr_recorded_check_in_date, check_out_date: vcr_recorded_check_out_date}
      }.to raise_error(ZumataV3::BadRequestError)
    end

  end

  describe "pre_book" do

    def sample_search destination_id="f75a8cff-c26e-4603-7b45-1b0f8a5aa100"
      return {
        :destination_id => destination_id,
        :check_in_date => "2015-08-04",
        :check_out_date => "2015-08-05",
        :room_count => 1,
        :adult_count => 2
      }
    end

    def sample_package
      return {
        :hotel_id => "240a3ae3-638d-4361-7b88-9bb830df872e",
        :room_details => {
          :description => "Executive Club",
          :food => 0,
          :room_type => "Executive Club",
          :room_view => "",
          :beds => {
            :double => 1
          }
        },
        :booking_key => "018adc8c",
        :room_rate => 62,
        :room_rate_currency => "USD",
        :chargeable_rate => 77,
        :chargeable_rate_currency => "USD"
      }
    end

    def sample_config
      return {
        :pricing => {
          :fixed_tolerance => 1
        },
        :matching => {
          :flexible_room_view => true,
          :flexible_beds => true
        }
      }
    end

    it 'pre-books a package returned from the search request' , :vcr => { :cassette_name => "pre_book_done", :record => :new_episodes } do
      results = @client.pre_book sample_search, sample_package, sample_config
    	data = JSON.parse(results.body)
      expect(data).to_not be(nil)
    end

    it 'raises an error if invalid inputs are provided', :vcr => { :cassette_name => "pre_book_fail", :record => :new_episodes } do
      expect{
        @client.pre_book sample_search("invalid_destination_id"), sample_package, sample_config
      }.to raise_error(ZumataV3::BadRequestError)
    end

  end

  describe "get_pre_book_by_id" do

    it 'returns a successful response if the query is valid', :vcr => { :cassette_name => "get_pre_book_by_id_done", :record => :new_episodes } do
      pre_book_id = "8f5b764c-1704-4d06-6797-01f184c390af"
      results = @client.get_pre_book_by_id pre_book_id
    	data = JSON.parse(results.body)
      expect(data).to_not be(nil)
    end

    it 'raises an error if invalid inputs are provided', :vcr => { :cassette_name => "get_pre_book_by_id_fail", :record => :new_episodes } do
      pre_book_id = "invalid"
      expect{
        results = @client.get_pre_book_by_id pre_book_id
      }.to raise_error(ZumataV3::NotFoundError)
    end

  end

  describe "book_by_credit" do

    def sample_guest
      return {
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
    end

    it 'books a package after a pre-booking request has been made (by credit) and return client reference', :vcr => { :cassette_name => "book_done", :record => :new_episodes } do
      pre_book_id = "8f5b764c-1704-4d06-6797-01f184c390af"
      results = @client.book_by_credit sample_guest, pre_book_id, {affiliate_key: ""}
    	data = JSON.parse(results.body)
      expect(data).to_not be(nil)
      expect(data["reference"]).not_to eq(nil)
    end

  end

  describe "get_book_by_reference_id" do

    it 'returns a successful response if the reference id is valid', :vcr => { :cassette_name => "get_book_by_reference_id_done", :record => :new_episodes } do
      reference_id = "820ad8f3-e97b-4eb2-7f3b-0f40b17b6b06"
      results = @client.get_book_by_reference_id reference_id
    	data = JSON.parse(results.body)
      expect(data).to_not be(nil)
      expect(data["client_reference"]).not_to eq(nil)
    end

    it 'raises an error if invalid reference id are provided', :vcr => { :cassette_name => "get_book_by_reference_id_fail", :record => :new_episodes } do
      reference_id = "invalid"
      expect{
        results = @client.get_book_by_reference_id reference_id
      }.to raise_error(ZumataV3::NotFoundError)
    end

  end

end
