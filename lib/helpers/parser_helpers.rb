module ParserHelpers
  def parse_params(params, path, method)
    accepted_file_classes = ['Rack::Multipart::UploadedFile', 'Hash']
    if params
      params.map do |param, value|
        value[:type] = 'file' if value.is_a?(Hash) and accepted_file_classes.include?(value[:type])
        
        dataType = value.is_a?(Hash) ? value[:type]||'String' : 'String'
        description = value.is_a?(Hash) ? value[:desc] || value[:description] : ''
        required = value.is_a?(Hash) ? !!value[:required] : false
        paramType = path.include?(":#{param}") ? 'path' : (method == 'POST') ? 'form' : 'query'
        name = (value.is_a?(Hash) && value[:full_name]) || param
        {
          paramType: paramType,
          name: name,
          description: description,
          dataType: dataType,
          required: required
        }
      end
    else
      []
    end
  end

  def parse_header_params(params)
    if params
      params.map do |param, value|
        dataType = 'String'
        description = value.is_a?(Hash) ? value[:description] : ''
        required = value.is_a?(Hash) ? !!value[:required] : false
        paramType = "header"
        {
          paramType: paramType,
          name: param,
          description: description,
          dataType: dataType,
          required: required
        }
      end
    else
      []
    end
  end

  def parse_path(path, version, hide_format)
    # adapt format to swagger format
    parsed_path = path.gsub '(.:format)', (hide_format ? '' : '.{format}')
    # This is attempting to emulate the behavior of
    # Rack::Mount::Strexp. We cannot use Strexp directly because
    # all it does is generate regular expressions for parsing URLs.
    # TODO: Implement a Racc tokenizer to properly generate the
    # parsed path.
    parsed_path = parsed_path.gsub(/:([a-zA-Z_]\w*)/, '{\1}')
    # add the version
    version ? parsed_path.gsub('{version}', version) : parsed_path
  end

  def parse_http_codes codes
    codes ||= {}
    codes.collect do |k, v|
      { code: k, reason: v }
    end
  end

  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      public_send(*a, &b) if respond_to?(a.first)
    end
  end

  def strip_heredoc(string)
    indent = string.scan(/^[ \t]*(?=\S)/).min.try(:size) || 0
    string.gsub(/^[ \t]{#{indent}}/, '')
  end

  def parse_base_path(base_path, request)
    (base_path.is_a?(Proc) ? base_path.call(request) : base_path) || request.base_url
  end
end

