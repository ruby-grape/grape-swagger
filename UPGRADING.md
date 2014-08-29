Upgrading Grape-swagger
=======================

### Upgrading to >= 0.8.0

#### Changes in configuration

The following options have been added, removed or have been changed in the grape-swagger interface:

* `markdown: boolean` => `markdown: GrapeSwagger::Markdown::KramdownAdapter.new` 


#### Markdown

Due performance issues with kramdown, the markdown option was changed from turning markdown on / off to a more flexible way, to configure a markdown plugin that you perfere or allready use. Markdown now needs to be configured with an adapter. The build in adapters are include for redcarpet and kramdown. Note that you still need to include the gems into your gemfile. Below are listed examples for both Kramdown and Redcarpet.

##### Kramdown

To configure the markdown with kramdown, add the kramdown gem to your gemfile:

`gem 'kramdown'`

Then configure grape-swagger with the option:

```ruby
add_swagger_documentation (
    markdown: GrapeSwagger::Markdown::KramdownAdapter.new
)
```
#### Redcarpet

To configure markdown with redcarpet, add the redcarpet and rouge gem to your gemfile. Note that redcarpet does not work in jruby. Add the following to your gemfile:

```ruby
gem 'redcarpet'
gem 'rouge'
``` 

And replace the grape-swagger configuration with:
```ruby
add_swagger_documentation (
    markdown: GrapeSwagger::Markdown::RedcarpetAdapter.new
)
```

See pull [#142](https://github.com/tim-vandecasteele/grape-swagger/pull/142) and documentation section [Markdown in Notes](https://github.com/tim-vandecasteele/grape-swagger#markdown-in-notes) for more information.
