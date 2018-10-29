# frozen_string_literal: true

GrapeInstance = if defined? Grape::API::Instance
                  Grape::API::Instance
                else
                  Grape::API
                end
