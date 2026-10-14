# frozen_string_literal: true

require 'json_schemer'

# `expect(doc).to be_valid_openapi('3.0' | '3.1')` validates a document (Hash or JSON string)
# against the OpenAPI meta-schemas bundled with json_schemer (JSONSchemer.openapi).
RSpec::Matchers.define :be_valid_openapi do |version|
  match do |doc|
    doc = JSON.parse(doc) if doc.is_a?(String)
    doc = JSON.parse(JSON.generate(doc))
    @version_ok = doc['openapi'].to_s.start_with?(version)
    @errors = JSONSchemer.openapi(doc).validate.map { |e| "#{e['data_pointer']}: #{e['type']} #{e['error']}" }
    @version_ok && @errors.empty?
  end

  failure_message do
    "expected a valid OpenAPI #{version} document#{' (openapi version mismatch)' unless @version_ok}, " \
      "got:\n  #{@errors.first(15).join("\n  ")}"
  end
end
