RSpec.shared_context "the api paths/defs" do
  let(:paths) {{
    "/in_body" => {
      post: {
        produces: ["application/json"],
        consumes: ["application/json"],
        parameters: [
          {in: "body", name: "in_body_1", description: "in_body_1", type: "integer", format: "int32", required: true},
          {in: "body", name: "in_body_2", description: "in_body_2", type: "string", required: false},
          {in: "body", name: "in_body_3", description: "in_body_3", type: "string", required: false}
        ],
        responses: {201 => {description: "post in body /wo entity", schema: {"$ref" => "#/definitions/InBody"}}},
        tags: ["in_body"],
        operationId: "postInBody"
      },
      get: {
        produces: ["application/json"],
        responses: {200 => {description: "get in path /wo entity", schema: {"$ref" => "#/definitions/InBody"}}},
        tags: ["in_body"],
        operationId: "getInBody"
      }
    },
    "/in_body/{key}" => {
      put: {
        produces: ["application/json"],
        consumes: ["application/json"],
        parameters: [
          {in: "path", name: "key", description: nil, type: "integer", format: "int32", required: true},
          {in: "body", name: "in_body_1", description: "in_body_1", type: "integer", format: "int32", required: true},
          {in: "body", name: "in_body_2", description: "in_body_2", type: "string", required: false},
          {in: "body", name: "in_body_3", description: "in_body_3", type: "string", required: false}
        ],
        responses: {200 => {description: "put in body /wo entity", schema: {"$ref" => "#/definitions/InBody"}}},
        tags: ["in_body"],
        operationId: "putInBodyKey"
      },
      get: {
        produces: ["application/json"],
        parameters: [
          {in: "path", name: "key", description: nil, type: "integer", format: "int32", required: true}
        ],
        responses: {200 => {description: "get in path /wo entity", schema: {"$ref" => "#/definitions/InBody"}}},
        tags: ["in_body"],
        operationId: "getInBodyKey"
    }}
  }}

  let(:found_path) {{
    post: {
      produces: ["application/json"],
      consumes: ["application/json"],
      parameters: [
        {in: "body", name: "in_body_1", description: "in_body_1", type: "integer", format: "int32", required: true},
        {in: "body", name: "in_body_2", description: "in_body_2", type: "string", required: false},
        {in: "body", name: "in_body_3", description: "in_body_3", type: "string", required: false}
      ],
      responses: {201 =>  {description: "post in body /wo entity", schema: {"$ref"=>"#/definitions/InBody"}}},
      tags: ["in_body"],
      operationId: "postInBody"
  }}}

  let(:definitions) {{
    "InBody" => {
      type: "object",
      properties: {
        in_body_1: {type: "integer", format: "int32"},
        in_body_2: {type: "string"},
        in_body_3: {type: "string"},
        key: {type: "integer", format: "int32"}
  }}}}

  let(:expected_post_defs) {{
    type: "object",
    properties: {
      in_body_1: {type: "integer", format: "int32", description: "in_body_1"},
      in_body_2: {type: "string", description: "in_body_2"},
      in_body_3: {type: "string", description: "in_body_3"}
    },
    :required=>[:in_body_1]
  }}

  let(:expected_put_defs) {{
    type: "object",
    properties: {
      in_body_1: {type: "integer", format: "int32", description: "in_body_1"},
      in_body_2: {type: "string", description: "in_body_2"},
      in_body_3: {type: "string", description: "in_body_3"},
      key: {type: "integer", format: "int32", readOnly: true}
    },
    :required=>[:in_body_1]
  }}

  let(:expected_path) {[]}
end
