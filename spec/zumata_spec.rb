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

  $vcr_recorded_check_in_date = "2015-07-24"
  $vcr_recorded_check_out_date = "2015-07-25"

  before(:each) do

    raise "Tests require environment variable 'ZUMATA_API_KEY' to be configured" unless ENV["ZUMATA_API_KEY"]

    ZumataV3.configure do |config|
      config.api_url = ENV["ZUMATA_API_URL"]
      config.api_key = ENV["ZUMATA_API_KEY"]
    end

    @client = ZumataV3::HotelClient.new
  end

  describe "search_by_destination_id" do

    it 'returns a successful response if the query is valid', :vcr => { :cassette_name => "#{$vcr_recorded_check_in_date}/search_by_destination_id_done", :record => :new_episodes } do
      # note - when recording the cassette this requires a cached search w/ results to exist
      destination_id = "f75a8cff-c26e-4603-7b45-1b0f8a5aa100" # Singapore
      results = @client.search_by_destination_id destination_id, {check_in_date: $vcr_recorded_check_in_date, check_out_date: $vcr_recorded_check_out_date}
    	data = JSON.parse(results.body)
      expect(data).to_not be(nil)
      expect(data["search"]).to_not be(nil)
      expect(data["results"]).to_not be(nil)
    end

    it 'raises an error if invalid inputs are provided', :vcr => { :cassette_name => "#{$vcr_recorded_check_in_date}/search_by_destination_id_fail", :record => :new_episodes } do
      destination_id = "invalid"
      expect{
        @client.search_by_destination_id destination_id, {check_in_date: $vcr_recorded_check_in_date, check_out_date: $vcr_recorded_check_out_date}
      }.to raise_error(ZumataV3::BadRequestError)
    end

  end

  describe "pre_book" do

    def sample_search destination_id="f75a8cff-c26e-4603-7b45-1b0f8a5aa100"
      return {
        :destination_id => destination_id,
        :check_in_date => $vcr_recorded_check_in_date,
        :check_out_date => $vcr_recorded_check_out_date,
        :room_count => 1,
        :adult_count => 2
      }
    end

    def sample_package
      return {
        :hotel_id => "00d7ed72-2325-4225-5e95-02d340e48fe5",
        :room_details => {
          :description => "Superior",
          :food => 0,
          :room_type => "Superior",
          :room_view => "",
          :beds => {
            :single => 2
          }
        },
        :booking_key => "39c90b48",
        :room_rate => 144.92,
        :room_rate_currency => "USD",
        :chargeable_rate => 15,
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

    it 'pre-books a package returned from the search request and return booking information' , :vcr => { :cassette_name => "#{$vcr_recorded_check_in_date}/prebook_done", :record => :new_episodes } do
      results = @client.pre_book sample_search, sample_package, sample_config
    	data = JSON.parse(results.body)
      expect(data).to_not be(nil)
      expect(data["pre_book_id"]).to_not be(nil)
      expect(data["cancellation_policy"]["remarks"]).to_not be(nil)
      expect(data["cancellation_policy"]["cancellation_policies"]).to_not be(nil)
    end

    it 'raises an error if invalid inputs are provided', :vcr => { :cassette_name => "#{$vcr_recorded_check_in_date}/prebook_fail", :record => :new_episodes } do
      expect{
        @client.pre_book sample_search("invalid_destination_id"), sample_package, sample_config
      }.to raise_error(ZumataV3::BadRequestError)
    end

  end

  describe "pre_book_details" do

    it 'returns a successful response if the query is valid', :vcr => { :cassette_name => "#{$vcr_recorded_check_in_date}/get_prebook_done", :record => :new_episodes } do
      pre_book_id = "2b076a9d-9051-4ab5-57f7-59aaf9d8ce2d"
      results = @client.pre_book_details pre_book_id
    	data = JSON.parse(results.body)
      expect(data).to_not be(nil)
      expect(data["pre_book_id"]).to_not be(nil)
    end

    it 'raises an error if pre-book id provided is invalid', :vcr => { :cassette_name => "#{$vcr_recorded_check_in_date}/get_prebook_fail", :record => :new_episodes } do
      pre_book_id = "invalid"
      expect{
        results = @client.pre_book_details pre_book_id
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

    it 'books a package after a pre-booking request has been made (by credit) and return client reference', :vcr => { :cassette_name => "#{$vcr_recorded_check_in_date}/book_done", :record => :new_episodes } do
      pre_book_id = "2b076a9d-9051-4ab5-57f7-59aaf9d8ce2d"
      results = @client.book_by_credit sample_guest, pre_book_id, {affiliate_key: ""}
    	data = JSON.parse(results.body)
      expect(data).to_not be(nil)
      expect(data["reference"]).not_to eq(nil)
    end

  end

  describe "booking_status" do

    it 'returns a successful response if the reference id is valid', :vcr => { :cassette_name => "#{$vcr_recorded_check_in_date}/get_book_done", :record => :new_episodes } do
      reference = "cc7aa5e9-4cf4-436d-619d-29b7fd992c27"
      results = @client.booking_status reference
    	data = JSON.parse(results.body)
      expect(data).to_not be(nil)
      expect(data["client_reference"]).not_to eq(nil)
    end

    it 'raises an error if reference id provided is invalid', :vcr => { :cassette_name => "#{$vcr_recorded_check_in_date}/get_book_fail", :record => :new_episodes } do
      reference = "invalid"
      expect{
        results = @client.booking_status reference
      }.to raise_error(ZumataV3::NotFoundError)
    end

  end

  describe "cancel" do

    it "returns a successful response if the reference id is valid", :vcr => { :cassette_name => "#{$vcr_recorded_check_in_date}/cancel_done", :record => :new_episodes } do
      reference = "cc7aa5e9-4cf4-436d-619d-29b7fd992c27"
      results = @client.cancel reference
      data = JSON.parse(results.body)
      expect(data).to_not be(nil)
    end

    it "raise an error if reference id provided is already cancelled", :vcr => { :cassette_name => "#{$vcr_recorded_check_in_date}/cancel_cancelled", :record => :new_episodes } do
      reference = "cc7aa5e9-4cf4-436d-619d-29b7fd992c27"
      expect{
        results = @client.cancel reference
      }.to raise_error(ZumataV3::UnprocessableEntityError)
    end

    it "raise an error if reference id provided is invalid", :vcr => { :cassette_name => "#{$vcr_recorded_check_in_date}/cancel_fail", :record => :new_episodes } do
      reference = "invalid"
      expect{
        results = @client.cancel reference
      }.to raise_error(ZumataV3::NotFoundError)
    end

  end

end
