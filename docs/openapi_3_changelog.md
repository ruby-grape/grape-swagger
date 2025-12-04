# OpenAPI 3.0/3.1 Implementation - Change Summary

## Branch: `oas3`

This document summarizes all changes made to add OpenAPI 3.0 and 3.1 support.

---

## New Files Added

### API Model Layer (`lib/grape-swagger/api_model/`)

| File | Purpose |
|------|---------|
| `spec.rb` | Root specification container |
| `info.rb` | Info object (title, version, license, contact) |
| `server.rb` | Server definition with variables support |
| `path_item.rb` | Path with operations |
| `operation.rb` | HTTP operation (GET, POST, etc.) |
| `parameter.rb` | Query/path/header/cookie parameters |
| `request_body.rb` | Request body with content types |
| `response.rb` | Response definition with headers |
| `media_type.rb` | Content-type + schema wrapper |
| `schema.rb` | JSON Schema representation |
| `components.rb` | Components container (schemas, securitySchemes) |
| `security_scheme.rb` | Security definition |
| `header.rb` | Response header definition |
| `tag.rb` | Tag definition |

### Model Builders (`lib/grape-swagger/model_builder/`)

| File | Purpose |
|------|---------|
| `spec_builder.rb` | Converts Swagger hash → API Model |
| `operation_builder.rb` | Builds operations from route |
| `parameter_builder.rb` | Builds parameters |
| `response_builder.rb` | Builds responses |
| `schema_builder.rb` | Builds schemas from types |

### Exporters (`lib/grape-swagger/exporter/`)

| File | Purpose |
|------|---------|
| `base.rb` | Abstract base exporter |
| `swagger2.rb` | Swagger 2.0 passthrough |
| `oas30.rb` | OpenAPI 3.0.3 exporter |
| `oas31.rb` | OpenAPI 3.1.0 exporter |

### Module Loaders

| File | Purpose |
|------|---------|
| `api_model.rb` | Loads all API Model classes |
| `model_builder.rb` | Loads all Model Builder classes |
| `exporter.rb` | Loads all Exporter classes |

---

## Modified Files

### Core Changes

| File | Changes |
|------|---------|
| `lib/grape-swagger.rb` | Added requires for new modules |
| `lib/grape-swagger/endpoint.rb` | Added OAS3 export path, `build_openapi_spec` method |
| `lib/grape-swagger/doc_methods.rb` | Added `openapi_version` to DEFAULTS |

### Nullable Support

| File | Changes |
|------|---------|
| `lib/grape-swagger/doc_methods/parse_params.rb` | Added `document_nullable` method |
| `lib/grape-swagger/doc_methods/move_params.rb` | Added `nullable` to `property_keys` |
| `lib/grape-swagger/model_builder/schema_builder.rb` | Added nullable to `apply_param_constraints` |

---

## Test Files Added (`spec/openapi_v3/`)

| File | Tests | Description |
|------|-------|-------------|
| `openapi_version_spec.rb` | 10 | Version configuration |
| `integration_spec.rb` | 33 | Full API integration |
| `type_format_spec.rb` | 11 | Type/format mappings |
| `form_data_spec.rb` | 11 | Form data handling |
| `file_upload_spec.rb` | 5 | File uploads |
| `params_array_spec.rb` | 24 | Array parameters |
| `param_type_spec.rb` | 10 | Query/path/header params |
| `param_type_body_nested_spec.rb` | 12 | Nested body params |
| `response_models_spec.rb` | 15 | Response models |
| `composition_schemas_spec.rb` | 8 | allOf/oneOf/anyOf |
| `additional_properties_spec.rb` | 12 | additionalProperties |
| `discriminator_spec.rb` | 6 | Discriminator |
| `links_callbacks_spec.rb` | 11 | Links and callbacks |
| `extensions_spec.rb` | 7 | x- extensions |
| `detail_spec.rb` | 8 | Summary/description |
| `status_codes_spec.rb` | 11 | HTTP status codes |
| `null_type_spec.rb` | 6 | Null type handling |
| `nullable_fields_spec.rb` | 8 | Nullable fields |
| `nullable_handling_spec.rb` | 8 | Nullable integration |
| `oas31_features_spec.rb` | 18 | OAS 3.1 features |

**Total OAS3 Tests: 293**

---

## Key Features Implemented

### OAS 3.0 Features

- [x] `openapi: 3.0.3` version string
- [x] `servers` array (from host/basePath/schemes)
- [x] `components/schemas` (from definitions)
- [x] `components/securitySchemes` (from securityDefinitions)
- [x] `requestBody` (from body params)
- [x] Parameter `schema` wrapper
- [x] `nullable: true` for nullable types
- [x] `style`/`explode` (from collectionFormat)
- [x] Response `content` wrapper
- [x] Links in responses
- [x] Callbacks in operations
- [x] Discriminator for polymorphism

### OAS 3.1 Features

- [x] `openapi: 3.1.0` version string
- [x] `type: ["string", "null"]` for nullable
- [x] `license.identifier` (SPDX)
- [x] `webhooks` support
- [x] `jsonSchemaDialect`
- [x] `contentMediaType`/`contentEncoding`

---

## Commits (chronological)

1. **Initial API Model Layer** - Created all DTO classes
2. **Model Builders** - Convert Swagger hash to API Model
3. **Swagger2 Exporter** - Validate refactor with passthrough
4. **OAS30 Exporter** - OpenAPI 3.0 specific output
5. **OAS31 Exporter** - 3.1 differences (nullable, license)
6. **Integration** - Wire configuration, update endpoint.rb
7. **Type Format Spec** - Type/format mapping tests
8. **Form Data & File Upload** - Request body handling
9. **Params Array** - Array parameter handling
10. **Nested Body Params** - Complex body structures
11. **Response Models** - Success/failure models
12. **Composition Schemas** - allOf/oneOf/anyOf
13. **Additional Properties** - Entity ref handling
14. **Discriminator** - Polymorphism support
15. **Links & Callbacks** - OAS3 specific features
16. **P3 Specs** - param_type, extensions, detail, status_codes
17. **Nullable Handling** - Full nullable integration

---

## Usage Examples

### Enable OpenAPI 3.0

```ruby
add_swagger_documentation(openapi_version: '3.0')
```

### Enable OpenAPI 3.1

```ruby
add_swagger_documentation(openapi_version: '3.1')
```

### Nullable Fields

```ruby
params do
  optional :nickname, type: String, documentation: { nullable: true }
end
```

### Full Configuration

```ruby
add_swagger_documentation(
  openapi_version: '3.0',
  info: {
    title: 'My API',
    version: '1.0',
    description: 'API description',
    license: { name: 'MIT', url: 'https://opensource.org/licenses/MIT' }
  },
  security_definitions: {
    bearer: { type: 'http', scheme: 'bearer' }
  }
)
```

---

## Backward Compatibility

- **Default unchanged**: Without `openapi_version`, Swagger 2.0 is generated
- **All 478 existing tests pass**: No changes to Swagger 2.0 output
- **Same options work**: All existing configuration options are supported

---

## Test Results

```
771 examples, 0 failures, 2 pending

OAS3 specific: 293 examples, 0 failures
Swagger 2.0: 478 examples, 0 failures, 2 pending
```
