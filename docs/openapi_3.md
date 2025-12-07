# OpenAPI 3.0/3.1 Support

## Quick Start

```ruby
# Swagger 2.0 (default, unchanged)
add_swagger_documentation

# OpenAPI 3.0
add_swagger_documentation(openapi_version: '3.0')

# OpenAPI 3.1
add_swagger_documentation(openapi_version: '3.1')
```

## Configuration Options

```ruby
add_swagger_documentation(
  openapi_version: '3.1',
  info: {
    title: 'My API',
    version: '1.0',
    description: 'API description',
    license: {
      name: 'MIT',
      url: 'https://opensource.org/licenses/MIT',
      identifier: 'MIT'  # OAS 3.1 only (SPDX)
    }
  },
  security_definitions: {
    bearer: { type: 'http', scheme: 'bearer' }
  },
  # OAS 3.1 specific
  json_schema_dialect: 'https://json-schema.org/draft/2020-12/schema',
  webhooks: {
    newUser: {
      post: {
        summary: 'New user webhook',
        requestBody: { ... },
        responses: { '200' => { description: 'OK' } }
      }
    }
  }
)
```

## Key Differences from Swagger 2.0

| Aspect | Swagger 2.0 | OpenAPI 3.x |
|--------|-------------|-------------|
| Version | `swagger: '2.0'` | `openapi: '3.0.3'` / `'3.1.0'` |
| Body params | `in: body` parameter | `requestBody` object |
| Form params | `in: formData` | `requestBody` with content-type |
| File upload | `type: file` | `type: string, format: binary` |
| Schema refs | `#/definitions/X` | `#/components/schemas/X` |
| Host | `host`, `basePath`, `schemes` | `servers: [{url: "..."}]` |
| Security defs | `securityDefinitions` | `components/securitySchemes` |
| Param types | inline `type`, `format` | wrapped in `schema` |

## Nullable Fields

```ruby
params do
  optional :nickname, type: String, documentation: { nullable: true }
end
```

**OAS 3.0:** `{ "type": "string", "nullable": true }`

**OAS 3.1:** `{ "type": ["string", "null"] }`

## Architecture

```
Grape Routes
     │
     ▼
┌─────────────────────────────┐
│  Builder::Spec              │
│  (lib/grape-swagger/openapi)│
└─────────────────────────────┘
     │
     ▼
┌─────────────────────────────┐
│  OpenAPI Model Layer        │
│  (Document, Schema, etc.)   │
└─────────────────────────────┘
     │
     ├──────────────┬──────────────┐
     ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Swagger2 │  │  OAS30   │  │  OAS31   │
│ Exporter │  │ Exporter │  │ Exporter │
└──────────┘  └──────────┘  └──────────┘
```

## Backward Compatibility

- **Default unchanged**: Without `openapi_version`, Swagger 2.0 is generated
- **All existing options work**: Same configuration for both versions
- **Model parsers unchanged**: grape-entity, representable, etc. work as before
