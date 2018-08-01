module Seed
  class SearchResults
    attr_accessor :properties

    # @param hash, form of
    # {
    #   "status": "success",
    #   "pagination": {
    #     "page": 1,
    #     "start": 1,
    #     "end": 5,
    #     "num_pages": 1,
    #     "has_next": false,
    #     "has_previous": false,
    #     "total": 5
    #   },
    #   "results": [
    #     {
    #         "id": 2070,
    #         "property_id": 2070,
    #         "state": {
    #             "id": 8302,
    #             "extra_data": {
    #             "occupancy_type": "Retail",
    #             "floors_below_grade": 0,
    #             "longitude": -122.42768558472727,
    #             "premise_identifier": "PN 123",
    #             "floors_above_grade": 1,
    #             "latitude": 37.76937674999205,
    #             "footprint_floor_area": 73872.6457
    #         },
    #         "measures": [
    #           {
    #               "id": 457,
    #               "measure_id": "lighting_improvements.retrofit_with_light_emitting_diode_technologies",
    #               "category": "lighting_improvements",
    #               "name": "retrofit_with_light_emitting_diode_technologies",
    #               "category_display_name": "Lighting Improvements",
    #               "display_name": "Retrofit with light emitting diode technologies",
    #               "category_affected": "Lighting",
    #               "application_scale": "Entire site",
    #               "recommended": true,
    #               "implementation_status": "Evaluated",
    #               "cost_mv": 1000,
    #               "description": null,
    #               "cost_total_first": 10000,
    #               "cost_installation": 8000,
    #               "cost_material": 1000,
    #               "cost_capital_replacement": null,
    #               "cost_residual_value": null
    #           },
    #           "import_file_id": null,
    #           "organization_id": 3,
    #           "address_line_1": "123 Main St",
    #       },
    #       "cycle": {
    #         "id": 5,
    #         "name": "BRICR Test Cycle - 2010",
    #         "start": "2010-01-01T00:00:00Z",
    #         "end": "2010-12-31T23:00:00Z",
    #         "created": "2017-08-07T15:12:43.381364Z"
    #       },
    #       ...
    #     ]
    # }
    def self.from_hash(hash)
      search_results = SearchResults.new
      vars_to_parse = [:status, :results, :properties]

      # DLM: response does not include 'results', now this is just 'properties'
      hash.each do |name, value|
        if vars_to_parse.include? name
          if name == :results
            search_results.properties = value
          else
            search_results.instance_variable_set("@#{name}", value)
            search_results.class.__send__(:attr_accessor, name)
          end
        end
      end

      search_results
    end
  end
end
