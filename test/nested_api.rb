require 'grape'
require '../lib/grape-swagger'

class SimpleNestedApi < Grape::API
  desc "Nested root"
  get 'index' do
  end
end

class SimpleMountedApi < Grape::API
  mount SimpleNestedApi => '/nested'
  desc "Document root"
  get 'index' do
  end

  add_swagger_documentation mount_path: '/simple/swagger_doc'
end

class OtherSimpleMountedApi < Grape::API
  desc "other simple mounted api root"
  get 'index' do
  end

  add_swagger_documentation mount_path: '/other_simple/swagger_doc'
end

class SimpleApi < Grape::API
  mount SimpleMountedApi => '/api'
  mount OtherSimpleMountedApi => '/other_api'
end