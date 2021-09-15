# frozen_string_literal: true

RSpec.shared_context 'the api paths/defs' do
  let(:paths) do
    {
      '/in_body' => {
        post: {
          produces: ['application/json'],
          consumes: ['application/json'],
          parameters: [
            { in: 'body', name: 'in_body_1', description: 'in_body_1', type: 'integer', format: 'int32', required: true, example: 23 },
            { in: 'body', name: 'in_body_2', description: 'in_body_2', type: 'string', required: false },
            { in: 'body', name: 'in_body_3', description: 'in_body_3', type: 'string', required: false }
          ],
          responses: { 201 => { description: 'post in body /wo entity', schema: { '$ref' => '#/definitions/InBody' } } },
          tags: ['in_body'],
          operationId: 'postInBody'
        },
        get: {
          produces: ['application/json'],
          responses: { 200 => { description: 'get in path /wo entity', schema: { '$ref' => '#/definitions/InBody' } } },
          tags: ['in_body'],
          operationId: 'getInBody'
        }
      },
      '/in_body/{key}' => {
        put: {
          produces: ['application/json'],
          consumes: ['application/json'],
          parameters: [
            { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true },
            { in: 'body', name: 'in_body_1', description: 'in_body_1', type: 'integer', format: 'int32', required: true },
            { in: 'body', name: 'in_body_2', description: 'in_body_2', type: 'string', required: false },
            { in: 'body', name: 'in_body_3', description: 'in_body_3', type: 'string', required: false, example: 'my example string' }
          ],
          responses: { 200 => { description: 'put in body /wo entity', schema: { '$ref' => '#/definitions/InBody' } } },
          tags: ['in_body'],
          operationId: 'putInBodyKey'
        },
        get: {
          produces: ['application/json'],
          parameters: [
            { in: 'path', name: 'key', description: nil, type: 'integer', format: 'int32', required: true }
          ],
          responses: { 200 => { description: 'get in path /wo entity', schema: { '$ref' => '#/definitions/InBody' } } },
          tags: ['in_body'],
          operationId: 'getInBodyKey'
        }
      }
    }
  end

  let(:found_path) do
    {
      post: {
        produces: ['application/json'],
        consumes: ['application/json'],
        parameters: [
          { in: 'body', name: 'in_body_1', description: 'in_body_1', type: 'integer', format: 'int32', required: true },
          { in: 'body', name: 'in_body_2', description: 'in_body_2', type: 'string', required: false },
          { in: 'body', name: 'in_body_3', description: 'in_body_3', type: 'string', required: false }
        ],
        responses: { 201 => { description: 'post in body /wo entity', schema: { '$ref' => '#/definitions/InBody' } } },
        tags: ['in_body'],
        operationId: 'postInBody'
      }
    }
  end

  let(:definitions) do
    {
      'InBody' => {
        type: 'object',
        properties: {
          in_body_1: { type: 'integer', format: 'int32' },
          in_body_2: { type: 'string' },
          in_body_3: { type: 'string' },
          key: { type: 'integer', format: 'int32' }
        }
      }
    }
  end

  let(:expected_post_defs) do
    {
      type: 'object',
      properties: {
        in_body_1: { type: 'integer', format: 'int32', description: 'in_body_1', example: 23 },
        in_body_2: { type: 'string', description: 'in_body_2' },
        in_body_3: { type: 'string', description: 'in_body_3' }
      },
      required: [:in_body_1]
    }
  end

  let(:expected_put_defs) do
    {
      type: 'object',
      properties: {
        in_body_1: { type: 'integer', format: 'int32', description: 'in_body_1' },
        in_body_2: { type: 'string', description: 'in_body_2' },
        in_body_3: { type: 'string', description: 'in_body_3', example: 'my example string' }
      },
      required: [:in_body_1]
    }
  end

  let(:expected_path) { [] }
end
