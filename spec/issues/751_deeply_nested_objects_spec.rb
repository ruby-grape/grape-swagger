# frozen_string_literal: true

require 'spec_helper'

describe '751 deeply nested objects' do
  let(:app) do
    Class.new(Grape::API) do
      content_type :json, 'application/json; charset=UTF-8'
      default_format :json
      class Vrp < Grape::API
        def self.vrp_request_timewindow(this)
          this.optional(:start, types: [String, Float, Integer])
          this.optional(:end, types: [String, Float, Integer])
        end

        def self.vrp_request_point(this)
          this.requires(:id, type: String, allow_blank: false)
          this.optional(:matrix_index, type: Integer)
          this.optional(:location, type: Hash) do
            requires(:lat, type: Float, allow_blank: false)
            requires(:lon, type: Float, allow_blank: false)
          end
          this.at_least_one_of :matrix_index, :location
        end

        def self.vrp_request_activity(this)
          this.optional(:duration, types: [String, Float, Integer])
          this.requires(:point_id, type: String, allow_blank: false)
          this.optional(:timewindows, type: Array) do
            Vrp.vrp_request_timewindow(self)
          end
        end

        def self.vrp_request_service(this)
          this.requires(:id, type: String, allow_blank: false)
          this.optional(:skills, type: Array[String])

          this.optional(:activity, type: Hash) do
            Vrp.vrp_request_activity(self)
          end
          this.optional(:activities, type: Array) do
            Vrp.vrp_request_activity(self)
          end
          this.mutually_exclusive :activity, :activities
        end
      end

      namespace :vrp do
        resource :submit do
          desc 'Submit Problems', nickname: 'vrp'
          params do
            optional(:vrp, type: Hash, documentation: { param_type: 'body' }) do
              optional(:points, type: Array) do
                Vrp.vrp_request_point(self)
              end

              optional(:services, type: Array) do
                Vrp.vrp_request_service(self)
              end
            end
          end
          post do
            { vrp: params[:vrp] }.to_json
          end
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'Correctness of vrp Points' do
    let(:get_points_response) { subject['definitions']['postVrpSubmit']['properties']['vrp']['properties']['points'] }
    specify do
      expect(get_points_response).to eql(
        'type' => 'array',
        'items' => {
          'type' => 'object',
          'properties' => {
            'id' => {
              'type' => 'string'
            },
            'matrix_index' => {
              'type' => 'integer',
              'format' => 'int32'
            },
            'location' => {
              'type' => 'object',
              'properties' => {
                'lat' => {
                  'type' => 'number',
                  'format' => 'float'
                },
                'lon' => {
                  'type' => 'number',
                  'format' => 'float'
                }
              },
              'required' => %w[lat lon]
            }
          },
          'required' => ['id']
        }
      )
    end
  end

  describe 'Correctness of vrp Services' do
    let(:get_service_response) { subject['definitions']['postVrpSubmit']['properties']['vrp']['properties']['services'] }
    specify do
      expect(get_service_response).to include(
        'type' => 'array',
        'items' => {
          'type' => 'object',
          'properties' => {
            'id' => {
              'type' => 'string'
            },
            'skills' => {
              'type' => 'array',
              'items' => {
                'type' => 'string'
              }
            },
            'activity' => {
              'type' => 'object',
              'properties' => {
                'duration' => {
                  'type' => 'string'
                },
                'point_id' => {
                  'type' => 'string'
                },
                'timewindows' => {
                  'type' => 'array',
                  'items' => {
                    'type' => 'object',
                    'properties' => {
                      'start' => {
                        'type' => 'string'
                      },
                      'end' => {
                        'type' => 'string'
                      }
                    }
                  }
                }
              },
              'required' => ['point_id']
            }, 'activities' => {
              'type' => 'array',
              'items' => {
                'type' => 'object',
                'properties' => {
                  'duration' => {
                    'type' => 'string'
                  },
                  'point_id' => {
                    'type' => 'string'
                  },
                  'timewindows' => {
                    'type' => 'array',
                    'items' => {
                      'type' => 'object',
                      'properties' => {
                        'start' => {
                          'type' => 'string'
                        },
                        'end' => {
                          'type' => 'string'
                        }
                      }
                    }
                  }
                },
                'required' => ['point_id']
              }
            }
          },
          'required' => ['id']
        }
      )
    end
  end
end
