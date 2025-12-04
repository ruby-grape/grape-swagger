# OpenAPI 3.0/3.1 Implementation Guide

This document provides a comprehensive overview of the OpenAPI 3.0 and 3.1 support added to grape-swagger.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Key Differences from Swagger 2.0](#key-differences-from-swagger-20)
5. [Implementation Details](#implementation-details)
6. [File Structure](#file-structure)
7. [API Model Layer](#api-model-layer)
8. [Exporters](#exporters)
9. [Model Builders](#model-builders)
10. [OAS 3.0 vs 3.1 Differences](#oas-30-vs-31-differences)
11. [Test Coverage](#test-coverage)

---

## Overview

### What Was Added

The implementation adds full OpenAPI 3.0 and 3.1 support to grape-swagger while maintaining complete backward compatibility with Swagger 2.0. The key addition is a **layered architecture** that separates:

1. **Route Introspection** - Existing Grape endpoint analysis (unchanged)
2. **API Model Layer** - Version-agnostic internal representation (NEW)
3. **Exporters** - Version-specific output formatters (NEW)

### Purpose

- Generate valid OpenAPI 3.0.3 and 3.1.0 specifications from Grape APIs
- Support modern OpenAPI features (requestBody, components, servers, etc.)
- Maintain 100% backward compatibility with existing Swagger 2.0 output
- Enable gradual migration path for existing users

### How to Use

```ruby
# Swagger 2.0 (default, unchanged)
add_swagger_documentation

# OpenAPI 3.0
add_swagger_documentation(openapi_version: '3.0')

# OpenAPI 3.1
add_swagger_documentation(openapi_version: '3.1')
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Grape Route Introspection                  │
│              (existing endpoint.rb logic)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    API Model Layer (NEW)                     │
│   Version-agnostic internal representation (DTOs)           │
│   - ApiModel::Spec, Info, Server                            │
│   - ApiModel::PathItem, Operation, Parameter                │
│   - ApiModel::Response, RequestBody, Schema                 │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌───────────────────┐ ┌───────────────┐ ┌───────────────┐
│  Swagger2Exporter │ │ OAS30Exporter │ │ OAS31Exporter │
│   (swagger: 2.0)  │ │ (openapi: 3.0)│ │ (openapi: 3.1)│
│   #/definitions/  │ │ #/components/ │ │ type: [x,null]│
│   in: body        │ │ requestBody   │ │ license.id    │
└───────────────────┘ └───────────────┘ └───────────────┘
```

### Data Flow

**When `openapi_version: '3.0'` or `'3.1'` is set:**
1. **DirectSpecBuilder** builds ApiModel::Spec directly from Grape routes
2. **Exporter** (OAS30/OAS31) converts ApiModel::Spec → OpenAPI output

**When no `openapi_version` is set (default):**
1. **Grape Endpoint** generates Swagger 2.0 hash (existing behavior unchanged)

---

## Quick Start

### Basic Usage

```ruby
class MyAPI < Grape::API
  format :json

  desc 'Get all users'
  get '/users' do
    User.all
  end

  # Enable OpenAPI 3.0
  add_swagger_documentation(openapi_version: '3.0')
end
```

### Output Comparison

**Swagger 2.0:**
```json
{
  "swagger": "2.0",
  "info": { "title": "API", "version": "1.0" },
  "host": "api.example.com",
  "basePath": "/v1",
  "paths": { ... },
  "definitions": { ... }
}
```

**OpenAPI 3.0:**
```json
{
  "openapi": "3.0.3",
  "info": { "title": "API", "version": "1.0" },
  "servers": [{ "url": "https://api.example.com/v1" }],
  "paths": { ... },
  "components": { "schemas": { ... } }
}
```

---

## Key Differences from Swagger 2.0

| Aspect | Swagger 2.0 | OpenAPI 3.x |
|--------|-------------|-------------|
| Version | `swagger: '2.0'` | `openapi: '3.0.3'` / `'3.1.0'` |
| Body params | `in: body` parameter | `requestBody` object |
| Form params | `in: formData` | `requestBody` with `multipart/form-data` |
| File upload | `type: file` | `type: string, format: binary` |
| Content types | global `produces`/`consumes` | per-operation `content` |
| Schema refs | `#/definitions/X` | `#/components/schemas/X` |
| Host | `host`, `basePath`, `schemes` | `servers: [{url: "..."}]` |
| Security defs | `securityDefinitions` | `components/securitySchemes` |
| Param types | inline `type`, `format` | wrapped in `schema` |
| Nullable (3.0) | N/A | `nullable: true` |
| Nullable (3.1) | N/A | `type: ["string", "null"]` |

---

## Implementation Details

### Request Body Transformation

Swagger 2.0 body parameters are automatically converted to OAS3 requestBody:

```ruby
# Grape params
params do
  requires :name, type: String
  requires :email, type: String
end
post '/users' do
  # ...
end
```

**Swagger 2.0 output:**
```json
{
  "parameters": [{
    "in": "body",
    "name": "postUsers",
    "schema": { "$ref": "#/definitions/postUsers" }
  }]
}
```

**OpenAPI 3.0 output:**
```json
{
  "requestBody": {
    "required": true,
    "content": {
      "application/json": {
        "schema": { "$ref": "#/components/schemas/postUsers" }
      }
    }
  }
}
```

### Parameter Schema Wrapping

OAS3 requires parameters to have a `schema` wrapper:

**Swagger 2.0:**
```json
{ "name": "id", "in": "path", "type": "integer", "format": "int32" }
```

**OpenAPI 3.0:**
```json
{ "name": "id", "in": "path", "schema": { "type": "integer", "format": "int32" } }
```

### Nullable Handling

```ruby
params do
  optional :nickname, type: String, documentation: { nullable: true }
end
```

**OAS 3.0:** `{ "type": "string", "nullable": true }`

**OAS 3.1:** `{ "type": ["string", "null"] }`

---

## File Structure

```
lib/grape-swagger/
├── api_model/                    # Version-agnostic model classes
│   ├── spec.rb                   # Root specification container
│   ├── info.rb                   # Info object (title, version, license)
│   ├── server.rb                 # Server definition
│   ├── path_item.rb              # Path with operations
│   ├── operation.rb              # HTTP operation
│   ├── parameter.rb              # Query/path/header parameters
│   ├── request_body.rb           # Request body (OAS3)
│   ├── response.rb               # Response definition
│   ├── media_type.rb             # Content-type + schema wrapper
│   ├── schema.rb                 # JSON Schema representation
│   ├── components.rb             # Components container
│   ├── security_scheme.rb        # Security definition
│   ├── header.rb                 # Response header
│   └── tag.rb                    # Tag definition
│
├── model_builder/                # Builds API Model from Swagger hash
│   ├── spec_builder.rb           # Main builder, orchestrates conversion
│   ├── operation_builder.rb      # Builds operations
│   ├── parameter_builder.rb      # Builds parameters
│   ├── response_builder.rb       # Builds responses
│   └── schema_builder.rb         # Builds schemas
│
├── exporter/                     # Version-specific exporters
│   ├── base.rb                   # Abstract base exporter
│   ├── swagger2.rb               # Swagger 2.0 output (passthrough)
│   ├── oas30.rb                  # OpenAPI 3.0 output
│   └── oas31.rb                  # OpenAPI 3.1 output (extends oas30)
│
└── api_model.rb                  # Module loader
```

---

## API Model Layer

The API Model layer provides version-agnostic data structures:

### ApiModel::Spec

Root container for the entire specification:

```ruby
spec = GrapeSwagger::ApiModel::Spec.new
spec.info.title = "My API"
spec.info.version = "1.0"
spec.add_server(GrapeSwagger::ApiModel::Server.new(url: "https://api.example.com"))
spec.add_path("/users", path_item)
spec.components.add_schema("User", user_schema)
```

### ApiModel::Schema

Represents JSON Schema, used for request/response bodies and parameters:

```ruby
schema = GrapeSwagger::ApiModel::Schema.new(
  type: 'object',
  nullable: true,
  description: 'A user object'
)
schema.add_property('name', GrapeSwagger::ApiModel::Schema.new(type: 'string'))
schema.add_property('email', GrapeSwagger::ApiModel::Schema.new(type: 'string'))
schema.mark_required('name')
schema.mark_required('email')
```

### ApiModel::Operation

Represents an HTTP operation:

```ruby
operation = GrapeSwagger::ApiModel::Operation.new
operation.operation_id = "getUsers"
operation.summary = "List all users"
operation.tags = ["Users"]
operation.add_parameter(param)
operation.request_body = request_body
operation.add_response(200, success_response)
```

---

## Exporters

### Base Exporter

Provides common functionality for all exporters:

```ruby
class GrapeSwagger::Exporter::Base
  def initialize(spec)
    @spec = spec
  end

  def export
    raise NotImplementedError
  end
end
```

### OAS30 Exporter

Converts API Model to OpenAPI 3.0 format:

- Outputs `openapi: '3.0.3'`
- Converts `#/definitions/` → `#/components/schemas/`
- Wraps parameters in `schema`
- Converts body params → `requestBody`
- Uses `nullable: true` for nullable types

### OAS31 Exporter

Extends OAS30 with 3.1-specific features:

- Outputs `openapi: '3.1.0'`
- Uses `type: ["string", "null"]` instead of `nullable: true`
- Supports `license.identifier` (SPDX)
- Supports `webhooks`
- Supports `jsonSchemaDialect`

---

## Model Builders

### DirectSpecBuilder (Primary for OAS 3.x)

Builds ApiModel::Spec directly from Grape routes without going through Swagger 2.0 format. This is the recommended approach for OAS 3.x as it preserves all route options and properly handles nested entities.

```ruby
builder = GrapeSwagger::ModelBuilder::DirectSpecBuilder.new(
  endpoint, target_class, request, options
)
spec = builder.build(namespace_routes)
```

Key features:
- Direct route introspection (no information loss)
- Proper nested entity handling via model parsers
- Full support for requestBody, components, servers
- Handles Array[Entity] types and inline schemas
- Recursive exposure of $ref nested entities

### SpecBuilder (Conversion-based)

Converts existing Swagger 2.0 hash to ApiModel::Spec. Used when converting legacy specs:

```ruby
builder = GrapeSwagger::ModelBuilder::SpecBuilder.new(options)
spec = builder.build_from_swagger_hash(swagger_hash)
```

Handles:
- Info object construction
- Server building from host/basePath/schemes
- Path and operation building
- Definition → components/schemas conversion
- Security scheme conversion

### SchemaBuilder

Builds Schema objects from various inputs:

```ruby
builder = GrapeSwagger::ModelBuilder::SchemaBuilder.new(definitions)

# From type
schema = builder.build(String, nullable: true)

# From param hash
schema = builder.build_from_param({ type: 'string', nullable: true })

# From definition hash
schema = builder.build_from_definition({ type: 'object', properties: {...} })
```

---

## OAS 3.0 vs 3.1 Differences

### Nullable Handling

**OAS 3.0:**
```ruby
def nullable_keyword?
  true  # Use nullable: true
end
```

**OAS 3.1:**
```ruby
def nullable_keyword?
  false  # Use type array: ["string", "null"]
end
```

### License Identifier

OAS 3.1 supports SPDX license identifiers:

```ruby
add_swagger_documentation(
  openapi_version: '3.1',
  info: {
    license: {
      name: 'MIT',
      identifier: 'MIT'  # SPDX identifier (3.1 only)
    }
  }
)
```

### Webhooks (OAS 3.1)

```ruby
spec.add_webhook('newUser', webhook_path_item)
```

Output:
```json
{
  "webhooks": {
    "newUser": {
      "post": { ... }
    }
  }
}
```

### JSON Schema Dialect (OAS 3.1)

```ruby
spec.json_schema_dialect = 'https://json-schema.org/draft/2020-12/schema'
```

---

## Test Coverage

### Test Files

```
spec/openapi_v3/
├── openapi_version_spec.rb       # Version configuration
├── integration_spec.rb           # Full API integration tests
├── type_format_spec.rb           # Type/format mappings
├── form_data_spec.rb             # Form data handling
├── file_upload_spec.rb           # File upload handling
├── params_array_spec.rb          # Array parameter handling
├── param_type_spec.rb            # Query/path/header params
├── param_type_body_nested_spec.rb # Nested body params
├── response_models_spec.rb       # Response model handling
├── composition_schemas_spec.rb   # allOf/oneOf/anyOf
├── additional_properties_spec.rb # additionalProperties
├── discriminator_spec.rb         # Discriminator support
├── links_callbacks_spec.rb       # Links and callbacks
├── extensions_spec.rb            # x- extensions
├── detail_spec.rb                # Summary/description
├── status_codes_spec.rb          # HTTP status codes
├── null_type_spec.rb             # Null type handling
├── nullable_fields_spec.rb       # Nullable fields
├── nullable_handling_spec.rb     # Nullable integration
└── oas31_features_spec.rb        # OAS 3.1 specific features
```

### Test Counts

- **Total tests**: 771
- **OAS3 tests**: 293
- **All passing**: Yes

### Running Tests

```bash
# All tests
bundle exec rspec

# OAS3 tests only
bundle exec rspec spec/openapi_v3/

# Specific feature
bundle exec rspec spec/openapi_v3/nullable_handling_spec.rb
```

---

## Backward Compatibility

The implementation maintains 100% backward compatibility:

1. **Default behavior unchanged** - Without `openapi_version`, Swagger 2.0 is generated
2. **All existing tests pass** - No changes to Swagger 2.0 output
3. **Same configuration options** - All existing options work with OAS3
4. **Model parsers unchanged** - grape-entity, representable, etc. work as before

---

## Future Enhancements

Potential areas for future development:

1. **Reusable components** - responses, parameters, requestBodies in components
2. **XML support** - Schema XML properties
3. **Complex parameter serialization** - `content` instead of `schema`
4. **OpenAPI 3.2** - When specification is finalized

---

## Contributing

When adding new OAS3 features:

1. Add to appropriate API Model class
2. Update SpecBuilder if needed
3. Update OAS30 exporter (and OAS31 if different)
4. Add comprehensive tests
5. Update this documentation
