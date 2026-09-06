# frozen_string_literal: true

class GrapeVersion
  class << self
    def current_version
      Grape::VERSION
    end

    def satisfy?(requirement)
      Gem::Dependency.new('grape-test', requirement).match?('grape-test', current_version)
    end

    # Grape HEAD stores the desc key as :default_response and deprecates :default.
    # Older Grape has no ApiDescription constant at all (e.g. 2.1.3).
    def default_response_in_dsl?
      defined?(Grape::Util::ApiDescription) &&
        Grape::Util::ApiDescription::DSL_METHODS.include?(:default_response)
    end
  end
end
