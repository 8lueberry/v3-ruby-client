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

    it 'returns a response with search completed status if the query is valid', :vcr => { :cassette_name => "search_by_destination_id_done", :record => :new_episodes } do
      # note - when recording the cassette this requires a cached search w/ results to exist
      destination_id = "f75a8cff-c26e-4603-7b45-1b0f8a5aa100" # Singapore
      results = @client.search_by_destination_id destination_id, {checkin: vcr_recorded_check_in_date, checkout: vcr_recorded_check_out_date}
    	data = JSON.parse(results.body)
      expect(data).to_not be(nil)
    end

  end

end
