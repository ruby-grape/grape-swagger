### 0.10.4 (December 7, 2015)

* [#315](https://github.com/ruby-grape/grape-swagger/pull/315): Require `grape-entity` < 0.5.0 - [@dblock](https://github.com/dblock).

### 0.10.3 (December 7, 2015)

* [#292](https://github.com/ruby-grape/grape-swagger/pull/292): Support i18n - [@calfzhou](https://github.com/calfzhou).
* [#297](https://github.com/ruby-grape/grape-swagger/pull/297): Correct use of documentation param_type - [@fab-girard](https://github.com/fab-girard).
* [#305](https://github.com/ruby-grape/grape-swagger/pull/305): Speedup by parsing models smarter, not harder - [@jhollinger](https://github.com/jhollinger).

### 0.10.2 (August 19, 2015)

#### Features

* [#215](https://github.com/ruby-grape/grape-swagger/pull/223): Support swagger `defaultValue` without the need to set a Grape `default` - [@jv-dan](https://github.com/jv-dan).

#### Fixes

* [#273](https://github.com/ruby-grape/grape-swagger/pull/273): Fix for hide_format when API class uses a single format with Grape 0.12.0 - [@mattolson](https://github.com/mattolson).
* [#264](https://github.com/ruby-grape/grape-swagger/pull/264): Consistent header param types - [@QuickPay](https://github.com/QuickPay).
* [#260](https://github.com/ruby-grape/grape-swagger/pull/260), [#261](https://github.com/ruby-grape/grape-swagger/pull/261): Fixed endpoints that would wrongly be hidden if `hide_documentation_path` is set - [@QuickPay](https://github.com/QuickPay).
* [#259](https://github.com/ruby-grape/grape-swagger/pull/259): Fixed range values and converting integer :values range to a minimum/maximum numeric Range - [@u2](https://github.com/u2).
* [#252](https://github.com/ruby-grape/grape-swagger/pull/252): Allow docs to mounted in separate class than target - [@iangreenleaf](https://github.com/iangreenleaf).
* [#251](https://github.com/ruby-grape/grape-swagger/pull/251): Fixed model id equal to model name when root existing in entities - [@aitortomas](https://github.com/aitortomas).
* [#232](https://github.com/ruby-grape/grape-swagger/pull/232): Fixed missing raw array params - [@u2](https://github.com/u2).
* [#234](https://github.com/ruby-grape/grape-swagger/pull/234): Fixed range :values with float - [@azhi](https://github.com/azhi).
* [#225](https://github.com/ruby-grape/grape-swagger/pull/225): Fixed `param_type` to have it read from parameter's documentation hash - [@zsxking](https://github.com/zsxking).
* [#235](https://github.com/ruby-grape/grape-swagger/pull/235): Fixed nested entity names in parameters and as `$ref` in models - [@frodrigo](https://github.com/frodrigo).
* [#206](https://github.com/ruby-grape/grape-swagger/pull/206): Fixed 'is_array' in the return entity being ignored - [@igormoochnick](https://github.com/igormoochnick).
* [#266](https://github.com/ruby-grape/grape-swagger/pull/266): Respect primitive mapping on type and format attributes of 1.2 swagger spec - [@frodrigo](https://github.com/frodrigo).
* [#268](https://github.com/ruby-grape/grape-swagger/pull/268): Fixed handling of `type: Array[...]` - [@frodrigo](https://github.com/frodrigo).
* [#284](https://github.com/ruby-grape/grape-swagger/pull/284): Use new params syntax for swagger doc endpoint, fix an issue that `:name` params not recognized by `declared` method - [@calfzhou](https://github.com/calfzhou).
* [#286](https://github.com/ruby-grape/grape-swagger/pull/286): Use `detail` value for `notes` - fix an issue where `detail` value specified in a block passed to `desc` was ignored - [@rngtng](https://github.com/rngtng).

### 0.10.1 (March 11, 2015)

* [#227](https://github.com/ruby-grape/grape-swagger/issues/227): Fix: nested routes under prefix not documented - [@dblock](https://github.com/dblock).
* [#226](https://github.com/ruby-grape/grape-swagger/issues/226): Fix: be defensive with nil exposure types - [@dblock](https://github.com/dblock).

### 0.10.0 (March 10, 2015)

#### Features

* [#217](https://github.com/ruby-grape/grape-swagger/pull/217): Support Array of entities for proper rendering of grape-entity input dependencies - [@swistaczek](https://github.com/swistaczek).
* [#214](https://github.com/ruby-grape/grape-swagger/pull/214): Allow anything that responds to `call` to be used in `:hidden` - [@zbelzer](https://github.com/zbelzer).
* [#196](https://github.com/ruby-grape/grape-swagger/pull/196): If `:type` is omitted, see if it's available in `:using` - [@jhollinger](https://github.com/jhollinger).
* [#200](https://github.com/ruby-grape/grape-swagger/pull/200): Treat `type: Symbol` as string form parameter - [@ypresto](https://github.com/ypresto).
* [#207](https://github.com/ruby-grape/grape-swagger/pull/207): Support grape `mutually_exclusive` - [@mintuhouse](https://github.com/mintuhouse).
* [#220](https://github.com/ruby-grape/grape-swagger/pull/220): Support standalone appearance of namespace routes with a custom name instead of forced nesting - [@croeck](https://github.com/croeck).

#### Fixes

* [#221](https://github.com/ruby-grape/grape-swagger/pull/221): Fixed group parameters' name with type Array - [@u2](https://github.com/u2).
* [#211](https://github.com/ruby-grape/grape-swagger/pull/211): Fixed the dependency, just `require 'grape'` - [@u2](https://github.com/u2).
* [#210](https://github.com/ruby-grape/grape-swagger/pull/210): Fixed the range `:values` option, now exposed as `enum` parameters - [@u2](https://github.com/u2).
* [#208](https://github.com/ruby-grape/grape-swagger/pull/208): Fixed `Float` parameters, exposed as Swagger `float` types - [@u2](https://github.com/u2).
* [#216](https://github.com/ruby-grape/grape-swagger/pull/216), [#192](https://github.com/ruby-grape/grape-swagger/issues/192), [#189](https://github.com/ruby-grape/grape-swagger/issues/189): Fixed API route paths matching for root endpoints with `grape ~> 0.10.0`, specific `format` and `:path` versioning - [@dm1try](https://github.com/dm1try), [@minch](https://github.com/minch).

### 0.9.0 (December 19, 2014)

* [#91](https://github.com/ruby-grape/grape-swagger/issues/91): Fixed empty field for group parameters' name with type hash or Array - [@dukedave](https://github.com/dukedave).
* [#154](https://github.com/ruby-grape/grape-swagger/pull/154): Allow classes for type declarations inside documentation - [@mrmargolis](https://github.com/mrmargolis).
* [#162](https://github.com/ruby-grape/grape-swagger/pull/162): Fix performance issue related to having a large number of models - [@elado](https://github.com/elado).
* [#169](https://github.com/ruby-grape/grape-swagger/pull/169): Test against multiple versions of Grape - [@dblock](https://github.com/dblock).
* [#166](https://github.com/ruby-grape/grape-swagger/pull/166): Ensure compatibility with Grape 0.8.0 or newer - [@dblock](https://github.com/dblock).
* [#174](https://github.com/ruby-grape/grape-swagger/pull/172): Fix problem with using prefix name somewhere in api paths - [@grzesiek](https://github.com/grzesiek).
* [#176](https://github.com/ruby-grape/grape-swagger/pull/176): Added ability to load nested models recursively - [@sergey-verevkin](https://github.com/sergey-verevkin).
* [#179](https://github.com/ruby-grape/grape-swagger/pull/179): Document `Virtus::Attribute::Boolean` as boolean - [@eashman](https://github.com/eashman), [@dblock](https://github.com/dblock).
* [#178](https://github.com/ruby-grape/grape-swagger/issues/178): Fixed `Hash` parameters, now exposed as Swagger `object` types - [@dblock](https://github.com/dblock).
* [#167](https://github.com/ruby-grape/grape-swagger/pull/167): Support mutli-tenanted APIs, don't cache `base_path` - [@bradrobertson](https://github.com/bradrobertson), (https://github.com/dblock).
* [#185](https://github.com/ruby-grape/grape-swagger/pull/185): Support strings in `Grape::Entity.expose`'s `:using` option - [@jhollinger](https://github.com/jhollinger).

### 0.8.0 (August 30, 2014)

#### Features

* [#139](https://github.com/ruby-grape/grape-swagger/pull/139): Added support for `Rack::Multipart::UploadedFile` parameters - [@timgluz](https://github.com/timgluz).
* [#136](https://github.com/ruby-grape/grape-swagger/pull/136), [#94](https://github.com/ruby-grape/grape-swagger/pull/94): Recurse combination of namespaces when using mounted apps - [@renier](https://github.com/renier).
* [#100](https://github.com/ruby-grape/grape-swagger/pull/100): Added ability to specify a nickname for an endpoint - [@lhorne](https://github.com/lhorne).
* [#94](https://github.com/ruby-grape/grape-swagger/pull/94): Added support for namespace descriptions - [@renier](https://github.com/renier).
* [#110](https://github.com/ruby-grape/grape-swagger/pull/110), [#111](https://github.com/ruby-grape/grape-swagger/pull/111) - Added `responseModel` support - [@bagilevi](https://github.com/bagilevi).
* [#114](https://github.com/ruby-grape/grape-swagger/pull/114): Added support for generating nested models from composed Grape Entities - [@dspaeth-faber](https://github.com/dspaeth-faber).
* [#124](https://github.com/ruby-grape/grape-swagger/pull/124): Added ability to change the description and parameters of the API endpoints generated by grape-swagger - [@dblock](https://github.com/dblock).
* [#128](https://github.com/ruby-grape/grape-swagger/pull/128): Combine global models and endpoint entities - [@dspaeth-faber](https://github.com/dspaeth-faber).
* [#132](https://github.com/ruby-grape/grape-swagger/pull/132): Addes support for enum values in entity documentation and form parameters - [@Antek-drzewiecki](https://github.com/Antek-drzewiecki).
* [#142](https://github.com/ruby-grape/grape-swagger/pull/142), [#143](https://github.com/ruby-grape/grape-swagger/pull/143): Added support for kramdown, redcarpet and custom formatters - [@Antek-drzewiecki](https://github.com/Antek-drzewiecki).

#### Fixes

* [#105](https://github.com/ruby-grape/grape-swagger/pull/105): Fixed compatibility with Swagger-UI - [@CraigCottingham](https://github.com/CraigCottingham).
* [#87](https://github.com/ruby-grape/grape-swagger/pull/87): Fixed mapping of `default` to `defaultValue` - [@m-o-e](https://github.com/m-o-e).
* [#127](https://github.com/ruby-grape/grape-swagger/pull/127): Fixed `undefined method 'reject' for nil:NilClass` error for an invalid route, now returning 404 Not Found - [@dblock](https://github.com/dblock).
* [#135](https://github.com/ruby-grape/grape-swagger/pull/135): Fixed model inclusion in models with aliased references - [@cdarne](https://github.com/cdarne).

#### Dev

* [#126](https://github.com/ruby-grape/grape-swagger/pull/126): Rewritten demo in the `test` folder with CORS enabled - [@dblock](https://github.com/dblock).
* Rewritten .gemspec and removed Jeweler - [@dblock](https://github.com/dblock).
* Added `GrapeSwagger::VERSION` - [@dblock](https://github.com/dblock).
* Added Rubocop, Ruby-style linter - [@dblock](https://github.com/dblock).

### 0.7.2 (February 6, 2014)

* [#84](https://github.com/ruby-grape/grape-swagger/pull/84): Markdown is now Github Flavored Markdown - [@jeromegn](https://github.com/jeromegn).
* [#83](https://github.com/ruby-grape/grape-swagger/pull/83): Improved support for nested Entity types - [@jeromegn](https://github.com/jeromegn).
* [#79](https://github.com/ruby-grape/grape-swagger/pull/79): Added `dataType` to the `params` output - [@Phobos98](https://github.com/Phobos98).
* [#75](https://github.com/ruby-grape/grape-swagger/pull/75), [#82](https://github.com/ruby-grape/grape-swagger/pull/82): Added Swagger 1.2 support - [@joelvh](https://github.com/joelvh), [@jeromegn](https://github.com/jeromegn).
* [#73](https://github.com/ruby-grape/grape-swagger/pull/73): Added the ability to add additional API `info` - [@mattbeedle](https://github.com/mattbeedle).
* [#69](https://github.com/ruby-grape/grape-swagger/pull/69): Make relative `base_path` values absolute - [@dm1try](https://github.com/dm1try).
* [#66](https://github.com/ruby-grape/grape-swagger/pull/66): Fixed documentation generated for paths that don't match the base URL pattern - [@swistaczek](https://github.com/swistaczek).
* [#63](https://github.com/ruby-grape/grape-swagger/pull/63): Added support for hiding endpoints from the documentation - [@arturoherrero](https://github.com/arturoherrero).
* [#62](https://github.com/ruby-grape/grape-swagger/pull/62): Fixed handling of URLs with the `-` character - [@dadario](https://github.com/dadario).
* [#57](https://github.com/ruby-grape/grape-swagger/pull/57): Fixed documenting of multiple API versions - [@Drakula2k](https://github.com/Drakula2k).
* [#58](https://github.com/ruby-grape/grape-swagger/pull/58): Fixed resource groupings for prefixed APIs - [@aew](https://github.com/aew).
* [#56](https://github.com/ruby-grape/grape-swagger/pull/56): Fixed `hide_documentation_path` on prefixed APIs - [@spier](https://github.com/spier).
* [#54](https://github.com/ruby-grape/grape-swagger/pull/54): Adding support for generating swagger `responseClass` and models from Grape Entities - [@calebwoods](https://github.com/calebwoods).
* [#46](https://github.com/ruby-grape/grape-swagger/pull/46): Fixed translating parameter `type` to String, enables using Mongoid fields as parameter definitions - [@dblock](https://github.com/dblock).

### 0.6.0 (June 19, 2013)

* Added Rails 4 support - [@jrhe](https://github.com/jrhe).
* Fix: document APIs at root level - [@dblock](https://github.com/dblock).
* Added support for procs in basepath - [@ruby-grape](https://github.com/ruby-grape).
* Support both `:desc` and `:description` when describing parameters - [@dblock](https://github.com/dblock).
* Fix: allow parameters such as `name[]` - [@dblock](https://github.com/dblock).

### 0.5.0 (March 28, 2013)

* Added Grape 0.5.0 support - [@ruby-grape](https://github.com/ruby-grape).

### 0.4.0 (March 28, 2013)

* Support https - [@cutalion](https://github.com/cutalion).

### 0.3.0 (October 19, 2012)

* Added version support - [@agileanimal](https://github.com/agileanimal), [@fknappe](https://github.com/fknappe).
* Added support for nested parameters - [@ruby-grape](https://github.com/ruby-grape).
* Added basic support for specifying parameters that need to be passed in the header - [@agileanimal](https://github.com/agileanimal).
* Add possibility to hide the documentation paths in the generated swagger documentation - [@ruby-grape](https://github.com/ruby-grape).

### 0.2.1 (August 17, 2012)

* Added support for markdown in notes field - [@ruby-grape](https://github.com/ruby-grape).
* Fix: compatibility with Rails - [@qwert666](https://github.com/qwert666).
* Fix: swagger UI history - [@ruby-grape](https://github.com/ruby-grape).

### 0.2.0 (July 27, 2012)

* Use resource as root for swagger - [@ruby-grape](https://github.com/ruby-grape).
* Added support for file uploads, and proper `paramType` - [@ruby-grape](https://github.com/ruby-grape).
* Added tests - [@nathanvda](https://github.com/nathanvda).

### 0.1.0 (July 19, 2012)

* Added some configurability to the generated documentation - [@ruby-grape](https://github.com/ruby-grape).
* Adapted to rails plugin structure - [@ruby-grape](https://github.com/ruby-grape).
* Allowed cross origin, so swagger can be used from official site - [@ruby-grape](https://github.com/ruby-grape).

### 0.0.0 (July 19, 2012)

* Initial public release - [@ruby-grape](https://github.com/ruby-grape).
