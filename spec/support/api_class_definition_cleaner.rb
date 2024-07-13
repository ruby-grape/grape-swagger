# frozen_string_literal: true

# ApiClassDefinitionCleaner
#
# This module is designed to be included in the RSpec configuration.
# It provides hooks to track and remove classes that inherit from Grape::API,
# ensuring that no leftover classes interfere with subsequent tests.
module ApiClassDefinitionCleaner
  # An array to store the initial state of classes inheriting from Grape::API.
  # @return [Array<Class>]
  @initial_objects = []

  class << self
    # Accessor method to get and set the initial state of classes inheriting from Grape::API.
    #
    # @return [Array<Class>] the array of initial classes inheriting from Grape::API.
    attr_accessor :initial_objects
  end

  # Sets up before and after hooks to track and clean up classes inheriting from Grape::API.
  #
  # @param config [RSpec::Core::Configuration] The RSpec configuration object.
  def self.included(config)
    # Hook to run before all examples.
    # Tracks the initial state of classes inheriting from Grape::API.
    config.before(:all) do
      ApiClassDefinitionCleaner.initial_objects = ObjectSpace
                                                  .each_object(Class)
                                                  .select { |klass| klass < Grape::API }
    end

    # Hook to run after all examples.
    # Identifies and removes any new classes inheriting from Grape::API
    # that were defined during the examples, to ensure a clean state.
    config.after(:all) do
      current_objects = ObjectSpace
                        .each_object(Class)
                        .select { |klass| klass < Grape::API }
      new_objects = current_objects - ApiClassDefinitionCleaner.initial_objects
      next if new_objects.empty?

      new_objects.each do |object|
        parts = object.to_s.split('::')
        parent = parts.size > 1 ? Object.const_get(parts[0..-2].join('::')) : Object
        parent.send(:remove_const, parts.last.to_sym) if parent.const_defined?(parts.last.to_sym)
      end

      # Run garbage collection to ensure they are removed
      GC.start
    end
  end
end
