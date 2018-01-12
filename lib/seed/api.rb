module Seed
  # API class to work with SEED Platform
  class API
    attr_reader :cycle_obj

    def initialize(host)
      @host = "#{host}/api"
      @api_header = nil

      # read the username and api key from env vars (if set)
      if ENV['BRICR_SEED_USERNAME'] && ENV['BRICR_SEED_API_KEY']
        api_key(ENV['BRICR_SEED_USERNAME'], ENV['BRICR_SEED_API_KEY'])
      end

      # query the API to get the user id
      @user_id = get_user_id
      unless @user_id
        raise Exception('Could not authenticate SEED API or find user ID')
      end

      @organization = nil
      @cycle_obj = nil
      @cache = {}
    end

    # Set the API key for server
    def api_key(username, key)
      @api_header = "Basic #{Base64.strict_encode64("#{username}:#{key}")}"
    end

    def get_user_id
      response = RestClient.get("#{@host}/v2/users/current_user_id/", authorization: @api_header)
      if response.code == 200
        return JSON.parse(response, symbolize_names: true)[:pk]
      elsif response.code == 500
        return 'ERROR getting current_user_id'
      end
    end

    def awake?
      response = RestClient.get("#{@host}/v2/version/", authorization: @api_header)
      if response.code == 200
        return true
      else
        return false
      end
    rescue Exception => e
      puts "Could not authenticate the user with message '#{e}'"
      return false
    end

    def get_or_create_organization(name)
      # check if the organization exists
      response = RestClient.get("#{@host}/v2/organizations/", authorization: @api_header)
      if response.code == 200
        response = JSON.parse(response, symbolize_names: true)
      else
        return false
      end

      response[:organizations].each do |org|
        if org[:name] == name
          @organization = Organization.from_hash(org)
          return @organization
        end
      end

      # no organization found, create a new one
      body = {
        organization_name: name,
        user_id: @user_id
      }
      response = RestClient.post("#{@host}/v2/organizations/", body, authorization: @api_header)
      if response.code == 200 # this should be a 201, seed needs fixed
        response = JSON.parse(response, symbolize_names: true)
        @organization = Organization.from_hash(response[:organization])
        return @organization
      else
        return false
      end
    end

    def cycles(bypass_cache = false)
      return @cache[:cycles] if @cache[:cycles] && !bypass_cache

      @cache[:cycles] = []
      response = RestClient.get(
        "#{@host}/v2/cycles/?organization_id=#{@organization.id}",
        authorization: @api_header
      )
      if response.code == 200
        cycles = []
        response = JSON.parse(response, symbolize_names: true)
        response[:cycles].each do |cycle|
          cycles << Cycle.from_hash(cycle)
        end
        @cache[:cycles] = cycles
      else
        return false
      end
    end

    # create a new cycle from name, start_time, and end_time
    # check if the cycle already exists and if so then return the existing cycle (only looks at name!)
    def create_cycle(name, start_time, end_time)
      # return if cycle already exists
      test_cycle = cycle(name)
      return test_cycle if test_cycle

      body = {
        name: name,
        start: start_time.strftime('%Y-%m-%d %H:%MZ'),
        end: end_time.strftime('%Y-%m-%d %H:%MZ')
      }
      RestClient.post("#{@host}/v2/cycles/?organization_id=#{@organization.id}", body,
                      authorization: @api_header) do |response, _request, result|
        if result.code.to_i == 201
          response = JSON.parse(response, symbolize_names: true)
          @cycle_obj = Cycle.from_hash(response[:cycles])
          return @cycle_obj
        else
          return false
        end
      end
    end

    # set the cycle
    def cycle(name)
      cycles if @cache[:cycles].nil? || @cache[:cycles].empty?

      @cycle_obj = nil
      @cache[:cycles].each do |cycle|
        if name == cycle.name
          @cycle_obj = cycle
          return cycle
        end
      end

      false
    end

    # upload a buildingsync file
    # returns status and response information
    def upload_buildingsync(filename)
      if File.exist? filename
        payload = {
          organization_id: @organization.id,
          cycle_id: @cycle_obj.id,
          file_type: 1,
          multipart: true
        }

        RestClient.post("#{@host}/v2/building_file/", payload.merge(file: File.new(filename, 'rb')),
                        authorization: @api_header) do |response, _request, result|
          if result.code.to_i == 404
            raise 'Could not find endpoint'
          elsif result.code.to_i == 200
            response = JSON.parse(response, symbolize_names: true)
            return true, response
          else
            response = JSON.parse(response, symbolize_names: true)
            return false, response
          end
        end
      else
        [false, "Could not find file to upload: #{filename}"]
      end
    end

    # Return details about the property in an object
    def property(property_id)
      # return if cycle already exists
      test_cycle = cycle(name)
      return test_cycle if test_cycle

      body = {
        name: name,
        start: start_time.strftime('%Y-%m-%d %H:%MZ'),
        end: end_time.strftime('%Y-%m-%d %H:%MZ')
      }

      response = RestClient.get(
        "#{@host}/v2/properties/#{property_id}/?cycle_id=#{@cycle_obj.id}&organization_id=#{@organization.id}",
        authorization: @api_header
      )

      if response.code == 200
        response = JSON.parse(response, symbolize_names: true)
        return Property.from_hash(response[:cycles])
      else
        return false
      end
    end

    def delete_property_state(property_id)
      RestClient.delete(
        "#{@host}/v2/properties/#{property_id}/?cycle_id=#{@cycle_obj.id}&organization_id=#{@organization.id}",
        authorization: @api_header
      ) do |_response, _request, result|
        if result.code.to_i == 200
          return true
        else
          return false
        end
      end
    end

    def list_buildingsync_files(property_id)
      RestClient.get(
        "#{@host}/v2/properties/#{property_id}/?cycle_id=#{@cycle_obj.id}&organization_id=#{@organization.id}",
        authorization: @api_header
      ) do |response, _request, result|
        if result.code.to_i == 200
          response = JSON.parse(response, symbolize_names: true)
          if response[:state] && response[:state][:files]
            return response[:state][:files]
          else
            return []
          end
        else
          return []
        end
      end
    end

    # Search for a property based on the address_line_1, pm_property_id, custom_id, or jurisdiction_property_id
    # @param identifier_string, string
    # @param analysis_state, string, state of the analysis to return (Not Started, Started, Completed, Failed)
    def search(identifier_string, analysis_state, per_page = 25)
      identifier_string = '' if identifier_string.nil?
      analysis_state = '' if analysis_state.nil?
      uri = URI.escape("#{@host}/v2.1/properties/?cycle=#{@cycle_obj.id}&organization_id=#{@organization.id}&identifier=#{identifier_string}&analysis_state=#{analysis_state}&per_page=#{per_page}")
      response = RestClient.get(uri, authorization: @api_header)

      if response.code == 200
        response = JSON.parse(response, symbolize_names: true)
        return SearchResults.from_hash(response)
      else
        return false
      end
    end

    # update the property
    def update_property_by_buildingfile(property_id, filename)
      payload = {
        multipart: true,
        file_type: 1
      }

      uri = URI.escape("#{@host}/v2.1/properties/#{property_id}/update_with_building_sync/?cycle_id=#{@cycle_obj.id}&organization_id=#{@organization.id}")
      RestClient.put(uri, payload.merge(file: File.new(filename, 'rb')), authorization: @api_header) do |response, _request, result|
        if result.code.to_i == 200
          # return the updated property
          response = JSON.parse(response, symbolize_names: true)
          return Property.from_hash(response[:data][:property_view][:state])
        else
          return false, response
        end
      end
    end

    # This will probably not work exactly right currently. The PUT method will probably create a new State, but
    # will not copy over all the existing measures, scenarios, etc. #TODO: Need to adddress this
    def update_analysis_state(property_id, analysis_state)
      payload = {
        state: {
          analysis_state: analysis_state
        }
      }
      uri = URI.escape("#{@host}/v2/properties/#{property_id}/?cycle_id=#{@cycle_obj.id}&organization_id=#{@organization.id}")
      RestClient.put(uri, payload.to_json, authorization: @api_header, content_type: :json) do |response, _request, result|
        if result.code.to_i == 200
          return true, {}
        elsif result.code.to_i == 204
          return true, response
        elsif result.code.to_i == 422
          return false, response
        else
          return false, response
        end
      end
    end
  end
end
