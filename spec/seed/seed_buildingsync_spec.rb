require 'spec_helper'
require 'securerandom'
require 'date'

RSpec.describe Seed do
  describe 'BuildingSync' do
    before :example do
      host = ENV['BRICR_SEED_HOST'] || 'http://localhost:8000'
      @r = Seed::API.new(host)
      @r.get_or_create_organization('Cycle Test')
      @r.create_cycle('models 01', DateTime.parse('2010-01-01'), DateTime.parse('2010-12-31'))
    end

    it 'should upload a buildingsync file' do
      filename = File.expand_path('../files/buildingsync_ex01.xml', File.dirname(__FILE__))
      response = @r.upload_buildingsync(filename)

      expect(response[0]).to eq true
      expect(response[1][:status]).to eq 'success'
      expect(response[1][:data][:property_view][:state][:gross_floor_area]).to eq 77579.0
    end

    it 'should fail on a malformed buildingsync file' do
      filename = File.expand_path('../files/buildingsync_ex01_malformed.xml', File.dirname(__FILE__))
      response = @r.upload_buildingsync(filename)

      expect(response[0]).to eq true
      expect(response[1][:message][:warnings][0]).to include 'Skipped meter Resource1 because it had no valid readings'
      expect(response[1][:data][:property_view][:state][:gross_floor_area]).to eq nil
    end

    it 'should list buildingsync files on property' do
      # first upload buildingsync file
      filename = File.expand_path('../files/buildingsync_ex01.xml', File.dirname(__FILE__))
      response = @r.upload_buildingsync(filename)
      expect(response[0]).to eq true
      expect(response[1][:status]).to eq 'success'

      property_id = response[1][:data][:property_view][:id]
      files = @r.list_buildingsync_files(property_id)
      expect(files.size).to eq 1
      expect(files[0][:filename]).to eq 'buildingsync_ex01.xml'
    end

    it 'should delete a buildingsync file' do
      # first upload buildingsync file
      filename = File.expand_path('../files/buildingsync_ex01.xml', File.dirname(__FILE__))
      response = @r.upload_buildingsync(filename)
      expect(response[0]).to eq true
      expect(response[1][:status]).to eq 'success'

      property_id = response[1][:data][:property_view][:id]
      @r.delete_property_state(property_id)
    end

    it 'should search for the uploaded file' do
      # first upload buildingsync file
      filename = File.expand_path('../files/buildingsync_ex01.xml', File.dirname(__FILE__))
      response = @r.upload_buildingsync(filename)
      expect(response[0]).to eq true
      expect(response[1][:status]).to eq 'success'
      # puts JSON.pretty_generate(response[1])

      # search for the building
      search_results = @r.search('151', nil)
      expect(search_results.properties.size).to be >= 1
      expect(search_results.properties.first[:state][:extra_data][:footprint_floor_area]).to eq 215643.97259999998
      expect(search_results.properties.first[:state][:gross_floor_area]).to eq 77579.0
      # TODO: need to update the API to enable better support for the measures, too slow to include right now.
      # expect(search_results.properties.first[:state][:measures].size).to eq 26

      # verify that a property results can be made a property object
      property_state = Seed::Property.from_hash(search_results.properties.first[:state])

      # test searching by analysis_state
      search_results = @r.search(nil, 'Not Started')
      expect(search_results.properties.size).to be >= 1
      # puts search_results.properties
    end
  end
end
