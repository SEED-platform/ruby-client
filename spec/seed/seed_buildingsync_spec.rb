require 'spec_helper'
require 'securerandom'
require 'date'

RSpec.describe Seed do
  describe 'BuildingSync' do
    before :example do
      # @r = Seed::API.new("https://seed-platform.org")
      @r = Seed::API.new('http://localhost:8000')
      @r.get_or_create_organization('Cycle Test')
      @r.create_cycle('models 01', DateTime.parse('2010-01-01'), DateTime.parse('2010-12-31'))
    end

    it 'should upload a buildingsync file' do
      filename = File.expand_path('../files/buildingsync_ex01.xml', File.dirname(__FILE__))
      response = @r.upload_buildingsync(filename)

      # puts JSON.pretty_generate(response)
      expect(response[:status]).to eq 'success'
      expect(response[:data][:property_state][:gross_floor_area]).to eq 69_452.0
    end

    it 'should search for the uploaded file' do
      # first upload buildingsync file
      filename = File.expand_path('../files/buildingsync_ex01.xml', File.dirname(__FILE__))
      response = @r.upload_buildingsync(filename)
      expect(response[:status]).to eq 'success'

      # search for the building
      search_results = @r.search('e6a5de56-8234-4b4f-ba10-6af0ae612fd1')
      expect(search_results.properties.size).to be >= 1
      puts search_results.properties.size

      puts search_results.properties.first
      expect(search_results.properties.first[:state][:extra_data][:footprint_floor_area]).to eq 73_872.6457
      expect(search_results.properties.first[:state][:gross_floor_area]).to eq 69_452
      expect(search_results.properties.first[:state][:measures].size).to eq 2

      # verify that a property results can be made a property object
      property_state = Seed::Property.from_hash(search_results.properties.first[:state])
      puts property_state
      puts property_state.id

    end
  end
end
