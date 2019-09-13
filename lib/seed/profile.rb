module Seed
  class Profile
    # @param hash, form of
    # {
    #     "name": "Profile Name",
    #     "id": 2
    # }
    def self.from_hash(hash)
      profile = Profile.new
      vars_to_parse = [:name, :id]

      hash.each do |name, value|
        if vars_to_parse.include? name
          profile.instance_variable_set("@#{name}", value)
          profile.class.__send__(:attr_accessor, name)
        end
      end
      profile
    end
  end
end
