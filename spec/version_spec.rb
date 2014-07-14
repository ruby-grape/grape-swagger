require 'spec_helper'

describe GrapeSwagger do
  it '#version' do
    expect(GrapeSwagger::VERSION).to_not be_nil
    expect(GrapeSwagger::VERSION.split('.').count).to eq 3
  end
end
