require 'grape-entity'
require './api/entities'

module Api
  class Spline
    attr_accessor :id, :x, :y, :reticulated
  end

  module Endpoints
    class Root < Grape::API
      desc 'API Root'
      get do
        {
          splines_url: '/splines',
          file_url: '/file'
        }
      end
    end

    class Splines < Grape::API
      @@splines = []

      namespace :splines do
        #
        desc 'Get all splines',
             is_array: true,
             http_codes: [
               { code: 200, message: 'get Splines', model: Api::Entities::Splines },
               { code: 422, message: 'SplinesOutError' }
             ]
        get do
          present :items, @@splines, with: Entities::Splines
        end

        #
        desc 'Return a spline.',
             http_codes: [
               { code: 200, message: 'get Splines' },
               { code: 422, message: 'SplinesOutError' }
             ]
        params do
          requires :id, type: Integer, desc: 'Spline id.'
        end
        get ':id' do
          error!(code: 422, message: 'SplinesOutError') unless @@splines[params[:id] - 1]

          present @@splines[params[:id] - 1], with: Entities::Splines
        end

        #
        desc 'Create a spline.',
             http_codes: [
               { code: 201, message: 'Spline created', model: Api::Entities::Splines }
             ]
        params do
          requires :spline, type: Hash do
            requires :x, type: Numeric
            requires :y, type: Numeric
          end
          optional :reticulated, type: Boolean, default: true, desc: 'True if the spline is reticulated.'
        end
        post do
          spline = Spline.new
          spline.id = @@splines.size + 1
          spline.x =  (params[:spline][:x] / params[:spline][:y] || 0.0)
          spline.y =  (params[:spline][:y] / params[:spline][:x] || 0.0)
          spline.reticulated =  params[:reticulated]

          @@splines << spline

          present spline, with: Entities::Splines
        end

        #
        desc 'Update a spline.',
             http_codes: [
               { code: 200, message: 'update Splines', model: Api::Entities::Splines },
               { code: 422, message: 'SplinesOutError' }
             ]
        params do
          requires :id, type: Integer, desc: 'Spline id.'
          optional :spline, type: Hash do
            optional :x, type: Numeric
            optional :y, type: Numeric
          end
          optional :reticulated, type: Boolean, default: true, desc: 'True if the spline is reticulated.'
        end
        put ':id' do
          error!(code: 422, message: 'SplinesOutError') unless @@splines[params[:id] - 1]

          update_data = params[:spline]
          spline      = @@splines[params[:id] - 1]

          spline.reticulated = !!update_data[:reticulated]
          spline.x           = update_data[:x] / update_data[:y] || 0.0
          spline.y           = update_data[:y] / update_data[:x] || 0.0

          present spline, with: Entities::Splines
        end

        #
        desc 'Delete a spline.'
        params do
          requires :id, type: Integer, desc: 'Spline id.'
        end
        delete ':id' do
          error!(code: 422, message: 'SplinesOutError') unless @@splines[params[:id] - 1]

          @@splines.delete_at(params[:id] - 1)
          { 'deleted' => params[:id] }
        end
      end
    end

    class FileAccessor < Grape::API
      namespace :file do
        desc 'Update image',
             details: "# TEST api for testing uploading\n
                       # curl --form file=@splines.png http://localhost:9292/file/upload",
             content_type: 'application/octet-stream'
        post 'upload' do
          filename = params[:file][:filename]
          content_type 'binary', 'application/octet-stream'
          # env['api.format'] = :binary # there's no formatter for :binary, data will be returned "as is"
          header 'Content-Disposition', "attachment; filename*=UTF-8''#{URI.escape(filename)}"
          params[:file][:tempfile].read
        end
      end
    end
  end
end
