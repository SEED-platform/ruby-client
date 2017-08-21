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
      response = RestClient.post("#{@host}/v2/cycles/?organization_id=#{@organization.id}",
                                 body,
                                 authorization: @api_header)
      if response.code == 201
        response = JSON.parse(response, symbolize_names: true)
        @cycle_obj = Cycle.from_hash(response[:cycles])
        return @cycle_obj
      else
        return false
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
    def upload_buildingsync(filename)
      if File.exist? filename
        payload = {
          organization_id: @organization.id,
          cycle_id: @cycle_obj.id,
          file_type: 1,
          multipart: true
        }
        response = RestClient.post("#{@host}/v2/building_file/",
                                   payload.merge(file: File.new(filename, 'rb')),
                                   authorization: @api_header)

        if response.code == 200
          response = JSON.parse(response, symbolize_names: true)
          return response
        else
          return false
        end
      else
        false
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
        inst = Property.from_hash(response[:cycles])
        return inst
      else
        return false
      end
    end

    # Search for a property based on the address_line_1, pm_property_id, custom_id, or jurisdiction_property_id
    # @param identifier_string, string
    def search(identifier_string)
      uri = URI.escape("#{@host}/v2.1/properties/?cycle_id=#{@cycle_obj.id}&organization_id=#{@organization.id}&identifier=#{identifier_string}")
      response = RestClient.get(uri, authorization: @api_header)

      if response.code == 200
        response = JSON.parse(response, symbolize_names: true)
        inst = SearchResults.from_hash(response)
        return inst
      else
        return false
      end
    end
  end
end
