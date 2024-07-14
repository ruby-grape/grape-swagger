# frozen_string_literal: true

require 'openapi3_parser'

# This module helps to validate the response body of endpoint tests
# against an OpenAPI 3.0 schema.
module OpenAPI3ResponseValidationHelper
  include RSpec::Matchers

  # Sets up an `after` hook to validate the response after each test example.
  #
  # @param base [Class] the class including this module
  def self.included(base)
    base.after(:each) do
      next unless last_response
      next unless last_response.ok?

      validate_openapi3_response(last_response.body)
    end
  end

  # Validates the response body against an OpenAPI 3.0 schema.
  #
  # @param response_body [String] the response body to be validated
  def validate_openapi3_response(response_body)
    document = Openapi3Parser.load(response_body)
    return if document.valid?

    aggregate_failures 'validation against an OpenAPI3' do
      document.errors.errors.each do |error|
        expect(document.valid?).to be(true), "#{error.message} in context #{error.context}"
      end
    end
  end
end
