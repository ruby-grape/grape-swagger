require 'grape'
require '../lib/grape-swagger'

@@splines = {}

class Api < Grape::API
  format :json

  desc 'API Root'
  get do
    { splines_url: '/splines' }
  end

  namespace :splines do
    desc 'Return a spline.'
    params do
      requires :id, type: Integer, desc: 'Spline id.'
    end
    get ':id' do
      @@splines[params[:id]] || error!('Not Found', 404)
    end

    desc 'Update a spline.'
    params do
      requires :id, type: Integer, desc: 'Spline id.'
      optional :reticulated, type: Boolean, default: true, desc: 'True if the spline is reticulated.'
    end
    put ':id' do
      spline = (@@splines[params[:id]] || error!('Not Found', 404))
      spline[:reticulated] = params[:reticulated]
      spline
    end

    desc 'Create a spline.'
    params do
      optional :reticulated, type: Boolean, default: true, desc: 'True if the spline is reticulated.'
      requires :required_group, type: Hash do
        requires :required_param_1
        requires :required_param_2
      end
    end
    post do
      spline = { id: @@splines.size + 1, reticulated: params[:reticulated] }
      @@splines[@@splines.size + 1] = spline
      spline
    end

    desc 'Return all splines.'
    get do
      @@splines.values
    end

    # TEST api for testing uploading
    # curl --form file=@splines.png http://localhost:9292/splines/upload
    desc 'Update image'
    post 'upload' do
      filename = params[:file][:filename]
      content_type 'application/octet-stream'
      env['api.format'] = :binary # there's no formatter for :binary, data will be returned "as is"
      header 'Content-Disposition', "attachment; filename*=UTF-8''#{URI.escape(filename)}"
      params[:file][:tempfile].read
    end
  end

  add_swagger_documentation
end
