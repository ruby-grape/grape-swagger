Upgrading Grape-swagger
=======================

### Upgrading to >= 0.10.2

Previously, grape-swagger hid the format in the URL by default. This conflicted
with grape-swagger-rails that required grape-swagger to specify the format (see
below). Grape-swagger will now assume the `format :json` by default. To
revert, `add_swagger_documentation(format: nil)`

#### Grape-Swagger-Rails

You will no longer need to specify `add_swagger_documentation(format: :json).`

### Upgrading to >= 0.9.0

#### Grape-Swagger-Rails

If you're using [grape-swagger-rails](https://github.com/BrandyMint/grape-swagger-rails), remove the `.json` extension from `GrapeSwaggerRails.options.url`.

For example, change

```ruby
GrapeSwaggerRails.options.url = '/api/v1/swagger_doc.json'
```

to

```ruby
GrapeSwaggerRails.options.url = '/api/v1/swagger_doc'
```

See [#187](https://github.com/tim-vandecasteele/grape-swagger/issues/187) for more information.

#### Grape 0.10.0

If your API uses Grape 0.10.0 or newer with a single `format :json` directive, add `hide_format: true` to `add_swagger_documentation`. Otherwise nested routes will render with `.json` links to your API documentation, which will fail with a 404 Not Found.

### Upgrading to >= 0.8.0

#### Changes in Configuration

The following options have been added, removed or have been changed in the grape-swagger interface:

* `markdown: true/false` => `markdown: GrapeSwagger::Markdown::KramdownAdapter`

#### Markdown

You can now configure a markdown adapter. This was originally changed because of performance issues with Kramdown and the `markdown` option no longer takes a boolean argument. Built-in adapters include Kramdown and Redcarpet.

##### Kramdown

To configure the markdown with Kramdown, add the kramdown gem to your Gemfile:

`gem 'kramdown'`

Configure grape-swagger as follows:

```ruby
add_swagger_documentation (
    markdown: GrapeSwagger::Markdown::KramdownAdapter
)
```

#### Redcarpet

To configure markdown with Redcarpet, add the redcarpet and the rouge gem to your Gemfile. Note that Redcarpet does not work with JRuby.

```ruby
gem 'redcarpet'
gem 'rouge'
```

Configure grape-swagger as follows:

```ruby
add_swagger_documentation (
    markdown: GrapeSwagger::Markdown::RedcarpetAdapter
)
```

See [#142](https://github.com/tim-vandecasteele/grape-swagger/pull/142) and documentation section [Markdown in Notes](https://github.com/tim-vandecasteele/grape-swagger#markdown-in-notes) for more information.
