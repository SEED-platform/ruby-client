module Seed
  class Property
    def self.from_hash(hash)
      property = Property.new
      vars_to_parse = %i[name start end id]

      hash.each do |name, value|
        if vars_to_parse.include? name
          property.instance_variable_set("@#{name}", value)
          property.class.__send__(:attr_accessor, name)
        end
      end

      # convert some attributes to ruby DateTime
      property.start = DateTime.parse(property.start) unless defined?(property.start).nil?
      property.end = DateTime.parse(property.end) unless defined?(property.end).nil?

      property
    end

    def update(_new_data)
      puts 'updating property'
    end
  end
end
