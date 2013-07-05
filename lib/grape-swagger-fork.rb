require 'kramdown'
require 'grape_swagger_core'

module Grape
  class API
    extend GrapeSwaggerCore
  end
end