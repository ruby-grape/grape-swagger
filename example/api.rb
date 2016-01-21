# require 'active_support'
# require 'active_support/core_ext/string/inflections.rb'

module Api
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
    @@splines = {}

    namespace :splines do
      #
      desc 'Get all splines',
        is_array: true,
        http_codes: [
          { code: 200, message: 'get Splines' },
          { code: 422, message: 'SplinesOutError' }
        ]
      get do
        { splines: @@splines }
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
        error!({ code: 422, message: 'SplinesOutError' }) unless @@splines[params[:id]]
        { "declared_params" => declared(params), spline: @@splines[params[:id]] }
      end

      #
      desc 'Create a spline.',
        http_codes: [
          { code: 201, message: 'Spline created' }
        ]
      params do
        requires :spline, type: Hash do
          requires :x, type: Numeric
          requires :y, type: Numeric
        end
        optional :reticulated, type: Boolean, default: true, desc: 'True if the spline is reticulated.'
      end
      post do
        spline = params[:spline]
        x = (spline[:x]/spline[:y] || 0.0)
        y = (spline[:y]/spline[:x] || 0.0)

        spline = {
          id: @@splines.size + 1,
          x: x,
          y: y,
          reticulated: params[:reticulated]
        }

        @@splines[spline[:id]] = spline

        { "declared_params" => declared(params), spline: spline }
      end

      #
      desc 'Update a spline.'
      params do
        requires :id, type: Integer, desc: 'Spline id.'
        optional :spline, type: Hash do
          optional :x, type: Numeric
          optional :y, type: Numeric
        end
        optional :reticulated, type: Boolean, default: true, desc: 'True if the spline is reticulated.'
      end
      put ':id' do
        error!({ code: 422, message: 'SplinesOutError' }) unless @@splines[params[:id]]

        update_data = params[:spline]
        spline      = @@splines[params[:id]]

        spline[:reticulated] = !!update_data[:reticulated]
        spline[:x]           = update_data[:x]/update_data[:y] || 0.0
        spline[:y]           = update_data[:y]/update_data[:x] || 0.0

        @@splines[params[:id]] = spline

        { "declared_params" => declared(params), spline: @@splines[params[:id]] }
      end

      desc 'Delete a spline.'
      params do
        requires :id, type: Integer, desc: 'Spline id.'
      end
      delete ':id' do
        error!({ code: 422, message: 'SplinesOutError' }) unless @@splines[params[:id]]

        @@splines.delete_if { |key, _| key == params[:id] }

        { "declared_params" => declared(params), spline: "#{params[:id]} deleted" }
      end
    end
  end

  class FileAccessor < Grape::API
    # TEST api for testing uploading
    # curl --form file=@splines.png http://localhost:9292/file/upload
    namespace :file do
      desc 'Update image'
      post 'upload' do
        filename = params[:file][:filename]
        content_type 'application/octet-stream'
        env['api.format'] = :binary # there's no formatter for :binary, data will be returned "as is"
        header 'Content-Disposition', "attachment; filename*=UTF-8''#{URI.escape(filename)}"
        params[:file][:tempfile].read
      end
    end
  end

end
