class GrapeVersion
  class << self
    def current_version
      Grape::VERSION
    end

    def satisfy?(requirement)
      Gem::Dependency.new('grape-test', requirement).match?('grape-test', current_version)
    end
  end
end
