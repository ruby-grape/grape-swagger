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
    # Older Grape has no ApiDescription (2.1) or no DSL_METHODS on it (3.0).
    def default_response_in_dsl?
      return false unless defined?(Grape::Util::ApiDescription)

      desc = Grape::Util::ApiDescription
      desc.const_defined?(:DSL_METHODS) && desc::DSL_METHODS.include?(:default_response)
    end
  end
end
