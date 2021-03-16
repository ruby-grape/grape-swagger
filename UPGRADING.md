## Upgrading Grape-swagger

### Upgrading to >= 1.4.0

- Official support for ruby < 2.5 removed, ruby 2.5 only in testing mode, but no support.

### Upgrading to >= 1.3.0

- The model (entity) description no longer comes from the route description. It will have a default value: `<<EntityName>> model`.

### Upgrading to >= 1.2.0

- The entity_name class method is now called on parent classes for inherited entities. Now you can do this

```ruby
module Some::Long::Module
  class Base < Grape::Entity
    # ... other shared logic
    def self.entity_name
      "V2::#{self.to_s.demodulize}"
    end
  end

  def MyEntity < Base
    # ....
  end

  def OtherEntity < Base
    # revert back to the default behavior by hiding the method
    private_class_method :entity_name
  end
end
```

- Full class name is modified to use `_` separator (e.g. `A_B_C` instead of `A::B::C`).

### Upgrading to >= 1.1.0

Full class name is used for referencing entity by default (e.g. `A::B::C` instead of just `C`). `Entity` and `Entities` suffixes and prefixes are omitted (e.g. if entity name is `Entities::SomeScope::MyFavourite::Entity` only `SomeScope::MyFavourite` will be used).

### Upgrading to >= 0.26.1

The format can now be specified,
to achieve it for definition properties one have to use grape-swagger-entity >= 0.1.6.

Usage of option `markdown` won't no longer be supported,
cause OAPI accepts [GFM](https://help.github.com/articles/github-flavored-markdown) and plain text.
(see: [description of `Info`](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/2.0.md#info-object))

### Upgrading to >= 0.25.2

Avoids ambiguous documentation of array parameters,
by enforcing correct usage of both possibilities:

1. Array of primitive types
  ```ruby
  params do
    requires :foo, type: Array[String]
  end
  ```

2. Array of objects
  ```ruby
  params do
    requires :put_params, type: Array do
      requires :op, type: String
      requires :path, type: String
      requires :value, type: String
    end
  end
```

### Upgrading to >= 0.25.0

The global tag set now only includes tags for documented routes. This behaviour has impact in particular for calling the documtation of a specific route.

### Upgrading to >= 0.21.0

With grape >= 0.21.0, `grape-entity` support moved to separate gem `grape-swagger-entity`, if you use grape entity, update your Gemfile:

```ruby
gem 'grape-swagger'
gem 'grape-swagger-entity'
```

`add_swagger_documentation` has changed from
``` ruby
  add_swagger_documentation \
    api_version: '0.0.1'
```
to

``` ruby
  add_swagger_documentation \
    doc_version: '0.0.1'
```

The API version self, would be set by grape, see -> [spec for #403](https://github.com/ruby-grape/grape-swagger/blob/master/spec/issues/403_versions_spec.rb).



### Upgrading to >= 0.10.2

With grape >= 0.12.0, support for `notes` is replaced by passing a block `detail` option specified. For future compatibility, update your code:

```ruby
desc 'Get all kittens!', notes: 'this will expose all the kittens'
```

to

``` ruby
 desc 'Get all kittens!' do
  detail 'this will expose all the kittens'
end
```
Be aware of https://github.com/ruby-grape/grape/issues/920, currently grape accepts either an option hash OR a block for `desc`.

### Upgrading to >= 0.9.0

#### Grape-Swagger-Rails

If you're using [grape-swagger-rails](https://github.com/ruby-grape/grape-swagger-rails), remove the `.json` extension from `GrapeSwaggerRails.options.url`.

For example, change

```ruby
GrapeSwaggerRails.options.url = '/api/v1/swagger_doc.json'
```

to

```ruby
GrapeSwaggerRails.options.url = '/api/v1/swagger_doc'
```

See [#187](https://github.com/ruby-grape/grape-swagger/issues/187) for more information.

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

See [#142](https://github.com/ruby-grape/grape-swagger/pull/142) and documentation section [Markdown in Notes](https://github.com/ruby-grape/grape-swagger#markdown-in-notes) for more information.
