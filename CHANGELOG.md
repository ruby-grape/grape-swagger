### Next Release

* [#94](https://github.com/tim-vandecasteele/grape-swagger/pull/94): Added support for namespace descriptions - [@renier](https://github.com/renier).
* [#110](https://github.com/tim-vandecasteele/grape-swagger/pull/110), [#111](https://github.com/tim-vandecasteele/grape-swagger/pull/111) - Added `responseModel` support - [@bagilevi](https://github.com/bagilevi).
* [#105](https://github.com/tim-vandecasteele/grape-swagger/pull/105): Fixed compatibility with Swagger-UI - [@CraigCottingham](https://github.com/CraigCottingham).
* [#87](https://github.com/tim-vandecasteele/grape-swagger/pull/87): Fixed mapping of `default` to `defaultValue` - [@m-o-e](https://github.com/m-o-e).
* Rewritten .gemspec and removed Jeweler - [@dblock](https://github.com/dblock).
* Added `GrapeEntity::VERSION` - [@dblock](https://github.com/dblock).
* Added Rubocop, Ruby-style linter - [@dblock](https://github.com/dblock).
* Adding support for generating nested models from composed Grape Entities [@dspaeth-faber](https://github.com/dspaeth-faber)
* Your Contribution Here

### 0.7.2 (February 6, 2014)

* [#84](https://github.com/tim-vandecasteele/grape-swagger/pull/84): Markdown is now Github Flavored Markdown - [@jeromegn](https://github.com/jeromegn).
* [#83](https://github.com/tim-vandecasteele/grape-swagger/pull/83): Improved support for nested Entity types - [@jeromegn](https://github.com/jeromegn).
* [#79](https://github.com/tim-vandecasteele/grape-swagger/pull/79): Added `dataType` to the `params` output - [@Phobos98](https://github.com/Phobos98).
* [#75](https://github.com/tim-vandecasteele/grape-swagger/pull/75), [#82](https://github.com/tim-vandecasteele/grape-swagger/pull/82): Added Swagger 1.2 support - [@joelvh](https://github.com/joelvh), [@jeromegn](https://github.com/jeromegn).
* [#73](https://github.com/tim-vandecasteele/grape-swagger/pull/73): Added the ability to add additional API `info` - [@mattbeedle](https://github.com/mattbeedle).
* [#69](https://github.com/tim-vandecasteele/grape-swagger/pull/69): Make relative `base_path` values absolute - [@dm1try](https://github.com/dm1try).
* [#66](https://github.com/tim-vandecasteele/grape-swagger/pull/66): Fixed documentation generated for paths that don't match the base URL pattern - [@swistaczek](https://github.com/swistaczek).
* [#63](https://github.com/tim-vandecasteele/grape-swagger/pull/63): Added support for hiding endpoints from the documentation - [@arturoherrero](https://github.com/arturoherrero).
* [#62](https://github.com/tim-vandecasteele/grape-swagger/pull/62): Fixed handling of URLs with the `-` character - [@dadario](https://github.com/dadario).
* [#57](https://github.com/tim-vandecasteele/grape-swagger/pull/57): Fixed documenting of multiple API versions - [@Drakula2k](https://github.com/Drakula2k).
* [#58](https://github.com/tim-vandecasteele/grape-swagger/pull/58): Fixed resource groupings for prefixed APIs - [@aew](https://github.com/aew).
* [#56](https://github.com/tim-vandecasteele/grape-swagger/pull/56): Fixed `hide_documentation_path` on prefixed APIs - [@spier](https://github.com/spier).
* [#54](https://github.com/tim-vandecasteele/grape-swagger/pull/54): Adding support for generating swagger `responseClass` and models from Grape Entities - [@calebwoods](https://github.com/calebwoods).
* [#46](https://github.com/tim-vandecasteele/grape-swagger/pull/46): Fixed translating parameter `type` to String, enables using Mongoid fields as parameter definitions - [@dblock](https://github.com/dblock).

### 0.6.0 (June 19, 2013)

* Added Rails 4 support - [@jrhe](https://github.com/jrhe).
* Fix: document APIs at root level - [@dblock](https://github.com/dblock).
* Added support for procs in basepath - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* Support both `:desc` and `:description` when describing parameters - [@dblock](https://github.com/dblock).
* Fix: allow parameters such as `name[]` - [@dblock](https://github.com/dblock).

### 0.5.0 (March 28, 2013)

* Added Grape 0.5.0 support - [@tim-vandecasteele](https://github.com/tim-vandecasteele).

### 0.4.0 (March 28, 2013)

* Support https - [@cutalion](https://github.com/cutalion).

### 0.3.0 (October 19, 2012)

* Added version support - [@agileanimal](https://github.com/agileanimal), [@fknappe](https://github.com/fknappe).
* Added support for nested parameters - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* Added basic support for specifying parameters that need to be passed in the header - [@agileanimal](https://github.com/agileanimal).
* Add possibility to hide the documentation paths in the generated swagger documentation - [@tim-vandecasteele](https://github.com/tim-vandecasteele).

### 0.2.1 (August 17, 2012)

* Added support for markdown in notes field - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* Fix: compatibility with Rails - [@qwert666](https://github.com/qwert666).
* Fix: swagger UI history - [@tim-vandecasteele](https://github.com/tim-vandecasteele).

### 0.2.0 (July 27, 2012)

* Use resource as root for swagger - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* Added support for file uploads, and proper `paramType` - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* Added tests - [@nathanvda](https://github.com/nathanvda).

### 0.1.0 (July 19, 2012)

* Added some configurability to the generated documentation - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* Adapted to rails plugin structure - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* Allowed cross origin, so swagger can be used from official site - [@tim-vandecasteele](https://github.com/tim-vandecasteele).

### 0.0.0 (July 19, 2012)

* Initial public release - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
