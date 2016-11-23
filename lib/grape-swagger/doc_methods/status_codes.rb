module GrapeSwagger
  module DocMethods
    class StatusCodes
      class << self
        def get
          {
            get: { code: 200, message: 'get {item}(s)' },
            post: { code: 201, message: 'created {item}' },
            put: { code: 200, message: 'updated {item}' },
            patch: { code: 200, message: 'patched {item}' },
            # 200 for delete would only be used, if a success entity is given,
            # else it would be set to 204
            delete: { code: 200, message: 'deleted {item}' },
            head: { code: 200, message: 'head {item}' },
            options: { code: 200, message: 'option {item}' }
          }
        end
      end
    end
  end
end
