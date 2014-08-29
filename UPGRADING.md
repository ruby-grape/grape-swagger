Upgrading Grape-swagger
=======================

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
