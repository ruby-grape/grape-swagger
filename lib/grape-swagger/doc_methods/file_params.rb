# frozen_string_literal: true

module GrapeSwagger
    module DocMethods
      class FileParams
        class << self
          def includes_file_param?(params)
            return params.any? { |x| x[:type] == 'file' }
          end
  
          end
  
          def to_formdata(params)
            params.each { |x| x[:in] = 'formData' if x[:in] == 'body' }
          end
        end
      end
    end
  end
  