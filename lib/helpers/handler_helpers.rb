module HandlerHelpers 
  def get_requested_version(params)
    return params[:route_info].route_version if params.has_key?(:route_info)
    return @@target_class::combined_routes.keys.first
  end
end
