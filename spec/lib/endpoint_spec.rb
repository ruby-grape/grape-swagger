require 'spec_helper'

describe Grape::Endpoint do
  subject { described_class.new(Grape::Util::InheritableSetting.new, path: '/', method: :get) }
end
