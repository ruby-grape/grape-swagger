### Next

#### Features

* Your contribution here.

#### Fixes

* Your contribution here.


### 1.4.0 (March 20, 2021)

#### Features

* [#818](https://github.com/ruby-grape/grape-swagger/pull/818): Adds ruby 3.0 support - [@LeFnord](https://github.com/LeFnord).
* [#815](https://github.com/ruby-grape/grape-swagger/pull/815): Add required for multiple presents - [@MaximeRDY](https://github.com/MaximeRDY).

#### Fixes

* [#822](https://github.com/ruby-grape/grape-swagger/pull/822): Corrected the related parameter lookup on request params - [@Jack12816](https://github.com/Jack12816).


### 1.3.1 (November 1, 2020)

#### Features

* [#813](https://github.com/ruby-grape/grape-swagger/pull/813): Handle multiple presents - [@AntoineGuestin](https://github.com/AntoineGuestin).

#### Fixes

* [#811](https://github.com/ruby-grape/grape-swagger/pull/811): Fixes #809: supports utf8 route names - [@LeFnord](https://github.com/LeFnord).


### 1.3.0 (September 3, 2020)

#### Features

* [#804](https://github.com/ruby-grape/grape-swagger/pull/804): Don't overwrite model description with the route description - [@Bhacaz](https://github.com/Bhacaz).


### 1.2.1 (July 15, 2020)

#### Fixes

* [#801](https://github.com/ruby-grape/grape-swagger/pull/801): Fixes behaviour after grape upgrade to 1.4.0 - [@LeFnord](https://github.com/LeFnord).


### 1.2.0 (July 1, 2020)

#### Features

* [#794](https://github.com/ruby-grape/grape-swagger/pull/794): Allow `entity_name` to be inherited, fixes issue #659 - [@urkle](https://github.com/urkle).
* [#793](https://github.com/ruby-grape/grape-swagger/pull/793): Features/inheritance and discriminator - [@MaximeRDY](https://github.com/MaximeRDY).

#### Fixes

* [#798](https://github.com/ruby-grape/grape-swagger/pull/798): Modify full entity name separator - [@GarrettB71](https://github.com/GarrettB71).
* [#796](https://github.com/ruby-grape/grape-swagger/pull/796): Support grape 1.4.0 - [@thedanielhanke](https://github.com/thedanielhanke).


### 1.1.0 (April 20, 2020)

#### Features

* [#785](https://github.com/ruby-grape/grape-swagger/pull/785): Add extensions for params - [@MaximeRDY](https://github.com/MaximeRDY).
* [#782](https://github.com/ruby-grape/grape-swagger/pull/782): Allow passing class name as string for rake task initializer - [@misdoro](https://github.com/misdoro).
* [#786](https://github.com/ruby-grape/grape-swagger/pull/786): Use full entity name as a default - [@mrexox](https://github.com/mrexox).


### 1.0.0 (February 10, 2020)

#### Features

* [#777](https://github.com/ruby-grape/grape-swagger/pull/777): Make usage of grape >= 1.3, rack >= 2.1 - [@LeFnord](https://github.com/LeFnord).
* [#775](https://github.com/ruby-grape/grape-swagger/pull/775): Add in token_owner support to param hidden procs - [@urkle](https://github.com/urkle).


### 0.34.2 (January 20, 2020)

#### Fixes

* [#773](https://github.com/ruby-grape/grape-swagger/pull/773): Freeze rack version to 2.0.8 - [@LeFnord](https://github.com/LeFnord).


### 0.34.0 (January 11, 2020)

#### Features

* [#768](https://github.com/ruby-grape/grape-swagger/pull/768): Uses ruby 2.7, fixes grape to 1.2.5 (cause of dry-types) - [@LeFnord](https://github.com/LeFnord).
* [#761](https://github.com/ruby-grape/grape-swagger/pull/761): Add an option to configure root element for responses - [@bikolya](https://github.com/bikolya).
* [#749](https://github.com/ruby-grape/grape-swagger/pull/749): Drop support for Ruby 2.3 and below - [@LeFnord](https://github.com/LeFnord).

#### Fixes

* [#758](https://github.com/ruby-grape/grape-swagger/pull/758): Handle cases where a route's prefix is a nested URL - [@SimonKaluza](https://github.com/simonkaluza).
* [#757](https://github.com/ruby-grape/grape-swagger/pull/757): Fix `array_use_braces` for nested body params - [@bikolya](https://github.com/bikolya).
* [#756](https://github.com/ruby-grape/grape-swagger/pull/756): Fix reference creation when custom type for documentation is provided - [@bikolya](https://github.com/bikolya).
* [#764](https://github.com/ruby-grape/grape-swagger/pull/764): Fix root element for multi-word entities - [@bikolya](https://github.com/bikolya).


### 0.33.0 (June 21, 2019)

#### Fixes

* [#747](https://github.com/ruby-grape/grape-swagger/pull/747): Allow multiple different success responses - [@charanftp3](https://github.com/charanpanchagnula).
* [#746](https://github.com/ruby-grape/grape-swagger/pull/746): Fix path with optional format - [@fnordfish](https://github.com/fnordfish).
* [#743](https://github.com/ruby-grape/grape-swagger/pull/743): CI: use 2.4.6, 2.5.5 - [@olleolleolle](https://github.com/olleolleolle).
* [#737](https://github.com/ruby-grape/grape-swagger/pull/737): Add swagger endpoint guard to both doc endpoints - [@urkle](https://github.com/urkle).


### 0.32.1 (December 7, 2018)

#### Fixes

* [#731](https://github.com/ruby-grape/grape-swagger/pull/731): Skip empty parameters and tags arrays - [@fotos](https://github.com/fotos).
* [#729](https://github.com/ruby-grape/grape-swagger/pull/729): Allow empty security array for endpoints - [@fotos](https://github.com/fotos).


### 0.32.0 (November 26, 2018)

#### Features

* [#717](https://github.com/ruby-grape/grape-swagger/pull/717): Adds support for grape >= 1.2 - [@myxoh](https://github.com/myxoh).

#### Fixes

* [#720](https://github.com/ruby-grape/grape-swagger/pull/720): Fix: corrected `termsOfService` field name in additional info - [@dblock](https://github.com/dblock).


### 0.31.1 (October 23, 2018)

#### Features

* [#710](https://github.com/ruby-grape/grape-swagger/issues/710): Re-implement `api_documentation` and `specific_api_documentation` options - [@dblock](https://github.com/dblock).


### 0.31.0 (August 22, 2018)

#### Features

* [#622](https://github.com/ruby-grape/grape-swagger/pull/622): Add support for 'brackets' collection format - [@korstiaan](https://github.com/korstiaan).
* [#637](https://github.com/ruby-grape/grape-swagger/pull/637): Add an option to add braces to array params - [@adie](https://github.com/adie).
* [#688](https://github.com/ruby-grape/grape-swagger/pull/688): Use deep merge for nested parameter definitions - [@jdmurphy](https://github.com/jdmurphy).
* [#691](https://github.com/ruby-grape/grape-swagger/pull/691): Disregard order when parsing request params for arrays - [@jdmurphy](https://github.com/jdmurphy).
* [#696](https://github.com/ruby-grape/grape-swagger/pull/696): Delegate required properties parsing to model parsers - [@Bugagazavr](https://github.com/Bugagazavr).


### 0.30.1 (July 19, 2018)

#### Features

* [#686](https://github.com/ruby-grape/grape-swagger/pull/686): Allow response headers for responses with no content and for files - [@jdmurphy](https://github.com/jdmurphy).


### 0.30.0 (July 19, 2018)

#### Features

* [#684](https://github.com/ruby-grape/grape-swagger/pull/684): Add response headers - [@jdmurphy](https://github.com/jdmurphy).

#### Fixes

* [#681](https://github.com/ruby-grape/grape-swagger/pull/681): Provide error schemas when an endpoint can return a 204 - [@adstratm](https://github.com/adstratm).
* [#683](https://github.com/ruby-grape/grape-swagger/pull/683): Fix handling of arrays of complex entities in params so that valid OpenAPI spec is generated - [@jdmurphy](https://github.com/jdmurphy).


### 0.29.0 (May 22, 2018)

#### Features

* [#667](https://github.com/ruby-grape/grape-swagger/pull/667): Make route summary optional - [@obduk](https://github.com/obduk).
* [#670](https://github.com/ruby-grape/grape-swagger/pull/670): Add support for deprecated field - [@ioanatia](https://github.com/ioanatia).
* [#675](https://github.com/ruby-grape/grape-swagger/pull/675): Add response examples - [@gamartin](https://github.com/gamartin).

#### Fixes

* [#664](https://github.com/ruby-grape/grape-swagger/pull/662): Removed all references to obsolete `hide_format` parameter - [@jonmchan](https://github.com/jonmchan).
* [#669](https://github.com/ruby-grape/grape-swagger/pull/669): Fix handling of http status codes from routes - [@milgner](https://github.com/milgner).
* [#672](https://github.com/ruby-grape/grape-swagger/pull/672): Rename 'notes' to 'detail' in README - [@kjleitz](https://github.com/kjleitz).


### 0.28.0 (February 3, 2018)

#### Features

* [#622](https://github.com/ruby-grape/grape-swagger/pull/622): Add support for 'brackets' collection format - [@korstiaan](https://github.com/korstiaan).

#### Fixes

* [#631](https://github.com/ruby-grape/grape-swagger/pull/631): Fix order of mounts with overrides - [@adie](https://github.com/adie).
* [#267](https://github.com/ruby-grape/grape-swagger/pull/634): Fix mounting APIs in route_param namespaces - [@milgner](https://github.com/milgner), [@wojciechka](https://github.com/wojciechka).
* [#642](https://github.com/ruby-grape/grape-swagger/pull/642): Fix examples link in readme - [@iBublik](https://github.com/iBublik).
* [#641](https://github.com/ruby-grape/grape-swagger/pull/641): Exclude default success code if http_codes define one already - [@anakinj](https://github.com/anakinj).
* [#651](https://github.com/ruby-grape/grape-swagger/pull/651): Apply `values` and `default` of array params to its items - [@yewton](https://github.com/yewton).
* [#654](https://github.com/ruby-grape/grape-swagger/pull/654): Allow setting the consumes for PATCH methods - [@anakinj](https://github.com/anakinj).
* [#656](https://github.com/ruby-grape/grape-swagger/pull/656): Fix `description` field may be null - [@soranoba](https://github.com/soranoba).


### 0.27.3 (July 11, 2017)

#### Features

* [#613](https://github.com/ruby-grape/grape-swagger/pull/613): Fix Proc with arity one in param values - [@timothysu](https://github.com/timothysu).

#### Fixes

* [#616](https://github.com/ruby-grape/grape-swagger/pull/616): Fix swagger to show root path ([#605](https://github.com/ruby-grape/grape-swagger/issue/605)) - [@NightWolf007](https://github.com/NightWolf007).


### 0.27.2 (May 11, 2017)

#### Features

* [#608](https://github.com/ruby-grape/grape-swagger/pull/608): Support extensions on the root object - [@thogg4](https://github.com/thogg4).
* [#596](https://github.com/ruby-grape/grape-swagger/pull/596): Use route_settings for hidden and operations extensions - [@thogg4](https://github.com/thogg4).
* [#607](https://github.com/ruby-grape/grape-swagger/pull/607): Allow body parameter name to be specified - [@tjwp](https://github.com/tjwp).


### 0.27.1 (April 28, 2017)

#### Features

* [#602](https://github.com/ruby-grape/grape-swagger/pull/602): Allow security object to be defined - [@markevich](https://github.com/markevich).


### 0.27.0 (March 27, 2017)

#### Features

* [#583](https://github.com/ruby-grape/grape-swagger/pull/583): Issue #582: document file response - [@LeFnord](https://github.com/LeFnord).
* [#588](https://github.com/ruby-grape/grape-swagger/pull/588): Allow extension keys in Info object - [@mattyr](https://github.com/mattyr).
* [#589](https://github.com/ruby-grape/grape-swagger/pull/589): Allow overriding tag definitions in Info object - [@mattyr](https://github.com/mattyr).

#### Fixes

* [#580](https://github.com/ruby-grape/grape-swagger/pull/580): Issue #578: fixes duplicated path params - [@LeFnord](https://github.com/LeFnord).
* [#585](https://github.com/ruby-grape/grape-swagger/pull/585): Issue #584: do not mutate route.path - [@LeFnord](https://github.com/LeFnord).
* [#586](https://github.com/ruby-grape/grape-swagger/pull/586): Issue #587: Parameters delimited by dash cause exception - [@risa](https://github.com/risa).
* [#593](https://github.com/ruby-grape/grape-swagger/pull/593): Clarify hidden option in readme - [@thogg4](https://github.com/thogg4).


### 0.26.1 (February 3, 2017)

#### Features

* [#567](https://github.com/ruby-grape/grape-swagger/pull/567): Issue#566: removes markdown - [@LeFnord](https://github.com/LeFnord).
* [#568](https://github.com/ruby-grape/grape-swagger/pull/568): Adds code coverage w/ coveralls - [@LeFnord](https://github.com/LeFnord).
* [#570](https://github.com/ruby-grape/grape-swagger/pull/570): Removes dead code -> increases code coverage - [@LeFnord](https://github.com/LeFnord).
* [#576](https://github.com/ruby-grape/grape-swagger/pull/576): Allows custom format, for params and definition properties - [@LeFnord](https://github.com/LeFnord).

#### Fixes

* [#562](https://github.com/ruby-grape/grape-swagger/pull/562): The guard method should allow regular object methods as arguments - [@tim-vandecasteele](https://github.com/tim-vandecasteele).
* [#574](https://github.com/ruby-grape/grape-swagger/pull/574): Fixes #572: `is_array` should only be applied to success - [@LeFnord](https://github.com/LeFnord).


### 0.26.0 (January 9, 2017)

#### Features

* [#558](https://github.com/ruby-grape/grape-swagger/pull/558): Version cascading including dependency updates (includes: [LeFnord#27](https://github.com/LeFnord/grape-swagger/pull/27)) - [@LeFnord](https://github.com/LeFnord).
* [#535](https://github.com/ruby-grape/grape-swagger/pull/535): Add support for grape version cascading  - [@qinix](https://github.com/qinix).
* [#560](https://github.com/ruby-grape/grape-swagger/pull/560): Map clearly Grape desc/detail to Swagger summary/description - [@frodrigo](https://github.com/frodrigo).

#### Fixes

* [#561](https://github.com/ruby-grape/grape-swagger/pull/561): Rename failures to failure in readme - [@justincampbell](https://github.com/justincampbell).


### 0.25.3 (December 18, 2016)

#### Features

* [#554](https://github.com/ruby-grape/grape-swagger/pull/554): Updates travis.yml to align with grape  - [@LeFnord](https://github.com/LeFnord).

#### Fixes

* [#546](https://github.com/ruby-grape/grape-swagger/pull/546): Move development dependencies to Gemfile - [@olleolleolle](https://github.com/olleolleolle).
* [#547](https://github.com/ruby-grape/grape-swagger/pull/547): Use entity_name event if type come from a string - [@frodrigo](https://github.com/frodrigo).
* [#548](https://github.com/ruby-grape/grape-swagger/pull/548): Remove dots from operation id - [@frodrigo](https://github.com/frodrigo).
* [#553](https://github.com/ruby-grape/grape-swagger/pull/553): Align array params for post, put request - addition to [#540](https://github.com/ruby-grape/grape-swagger/pull/540) - [@LeFnord](https://github.com/LeFnord).


### 0.25.2 (November 30, 2016)

#### Fixes

* [#544](https://github.com/ruby-grape/grape-swagger/pull/544): Fixes #539 and #542; not all of 530 was commited - [@LeFnord](https://github.com/LeFnord).


### 0.25.1 (November 29, 2016)

#### Features

* [#531](https://github.com/ruby-grape/grape-swagger/pull/531): UUID data_type format support - [@migmartri](https://github.com/migmartri).
* [#534](https://github.com/ruby-grape/grape-swagger/pull/534): Allows to overwrite defaults status codes - [@LeFnord](https://github.com/LeFnord).

#### Fixes

* [#540](https://github.com/ruby-grape/grape-swagger/pull/540): Corrects exposing of array in post body - [@LeFnord](https://github.com/LeFnord).
* [#509](https://github.com/ruby-grape/grape-swagger/pull/509), [#529](https://github.com/ruby-grape/grape-swagger/pull/529): Making parent-less routes working - [@mur-wtag](https://github.com/mur-wtag).


### 0.25.0 (October 31, 2016)

#### Features

* [#524](https://github.com/ruby-grape/grape-swagger/pull/524): Use route tags for global tag set - [@LeFnord](https://github.com/LeFnord).
* [#523](https://github.com/ruby-grape/grape-swagger/pull/523): Allow specifying custom tags at the route level - [@jordanfbrown](https://github.com/jordanfbrown).
* [#520](https://github.com/ruby-grape/grape-swagger/pull/520): Response model can have required attributes - [@WojciechKo](https://github.com/WojciechKo).
* [#510](https://github.com/ruby-grape/grape-swagger/pull/510): Use 'token_owner' instead of 'oauth_token' on Swagger UI endpoint authorization - [@texpert](https://github.com/texpert).

#### Fixes

* [#527](https://github.com/ruby-grape/grape-swagger/pull/527): Accepts string as entity - [@LeFnord](https://github.com/LeFnord).
* [#515](https://github.com/ruby-grape/grape-swagger/pull/515): Removes limit on model names - [@LeFnord](https://github.com/LeFnord).
* [#511](https://github.com/ruby-grape/grape-swagger/pull/511): Fix incorrect data type linking for request params of entity types - [@serggl](https://github.com/serggl).


### 0.24.0 (September 23, 2016)

#### Features

* [#504](https://github.com/ruby-grape/grape-swagger/pull/504): Added support for set the 'collectionFormat' of arrays - [@rczjns](https://github.com/rczjns).
* [#502](https://github.com/ruby-grape/grape-swagger/pull/502): Adds specs for rake tasks - [@LeFnord](https://github.com/LeFnord).
* [#501](https://github.com/ruby-grape/grape-swagger/pull/501): Adds getting of a specified resource for Rake Tasks - [@LeFnord](https://github.com/LeFnord).
* [#500](https://github.com/ruby-grape/grape-swagger/pull/500): Adds Rake tasks to get and validate OAPI/Swagger documentation - [@LeFnord](https://github.com/LeFnord).
* [#493](https://github.com/ruby-grape/grape-swagger/pull/493): Swagger UI endpoint authorization - [@texpert](https://github.com/texpert).
* [#492](https://github.com/ruby-grape/grape/pull/492): Define security requirements on endpoint methods - [@tomregelink](https://github.com/tomregelink).
* [#497](https://github.com/ruby-grape/grape-swagger/pull/497): Use ruby-grape-danger in Dangerfile - [@dblock](https://github.com/dblock).

#### Fixes

* [#503](https://github.com/ruby-grape/grape-swagger/pull/503): Corrects exposing of inline definitions - [@LeFnord](https://github.com/LeFnord).
* [#494](https://github.com/ruby-grape/grape-swagger/pull/494): Header parametes are now included in documentation when body parameters have been defined - [@anakinj](https://github.com/anakinj).
* [#505](https://github.com/ruby-grape/grape-swagger/pull/505): Combines namespaces with their mounted paths to allow APIs with specified mount_paths - [@KevinLiddle](https://github.com/KevinLiddle).


### 0.23.0 (August 5, 2016)

#### Features

* [#491](https://github.com/ruby-grape/grape-swagger/pull/491): Add `ignore_defaults` option - [@pezholio](https://github.com/pezholio).
* [#486](https://github.com/ruby-grape/grape-swagger/pull/486): Use an automated PR linter, [danger.systems](http://danger.systems) - [@dblock](https://github.com/dblock).

#### Fixes

* [#489](https://github.com/ruby-grape/grape-swagger/pull/489): Makes version settings/usage more clear; updates `UPGRADE.md`, `README.md` - [@LeFnord](https://github.com/LeFnord).
* [#476](https://github.com/ruby-grape/grape-swagger/pull/476): Fixes for handling the parameter type when body parameters are defined inside desc block - [@anakinj](https://github.com/anakinj).
* [#478](https://github.com/ruby-grape/grape-swagger/pull/478): Refactors building of properties, corrects documentation of array items - [@LeFnord](https://github.com/LeFnord).
* [#479](https://github.com/ruby-grape/grape-swagger/pull/479): Fix regex for Array and Multi Type in doc_methods. Parsing of "[APoint]" should return "APoint" - [@frodrigo](https://github.com/frodrigo).
* [#483](https://github.com/ruby-grape/grape-swagger/pull/483): Added support for nicknamed routes - [@pbendersky](https://github.com/pbendersky).


### 0.22.0 (July 12, 2016)

#### Features

* [#470](https://github.com/ruby-grape/grape-swagger/pull/470): Document request definitions inline - [@LeFnord](https://github.com/LeFnord).
* [#448](https://github.com/ruby-grape/grape-swagger/pull/448): Header parameters are now prepended to the parameter list - [@anakinj](https://github.com/anakinj).
* [#444](https://github.com/ruby-grape/grape-swagger/pull/444): With multi types parameter the first type is use as the documentation type - [@scauglog](https://github.com/scauglog).
* [#463](https://github.com/ruby-grape/grape-swagger/pull/463): Added 'hidden' option for parameter to be exclude from generated documentation - [@anakinj](https://github.com/anakinj).
* [#471](https://github.com/ruby-grape/grape-swagger/pull/471): Allow Security Definitions Objects to be defined - [@bendodd](https://github.com/bendodd).

#### Fixes

* [#472](https://github.com/ruby-grape/grape-swagger/pull/472): Fixes required property for request definitions - [@LeFnord](https://github.com/LeFnord).
* [#467](https://github.com/ruby-grape/grape-swagger/pull/467): Refactors moving of body params - [@LeFnord](https://github.com/LeFnord).
* [#464](https://github.com/ruby-grape/grape-swagger/pull/464): Fixes array params, sets correct type and format for items - [@LeFnord](https://github.com/LeFnord).
* [#461](https://github.com/ruby-grape/grape-swagger/pull/461): Fixes issue by adding extensions to definitions. It appeared, if for the given status code, no definition could be found - [@LeFnord](https://github.com/LeFnord).
* [#455](https://github.com/ruby-grape/grape-swagger/pull/455): Setting `type:` option as `Array[Class]` creates `array` type in JSON - [@tyspring](https://github.com/tyspring).
* [#450](https://github.com/ruby-grape/grape-swagger/pull/438): Do not add :description to definitions if :description is missing on path - [@texpert](https://github.com/texpert).
* [#447](https://github.com/ruby-grape/grape-swagger/pull/447): Version part of the url is now ignored when generating tags for endpoint - [@anakinj](https://github.com/anakinj).
* [#444](https://github.com/ruby-grape/grape-swagger/pull/444): Default value provided in the documentation hash, override the grape default - [@scauglog](https://github.com/scauglog).
* [#443](https://github.com/ruby-grape/grape-swagger/issues/443): Type provided in the documentation hash, override the grape type - [@scauglog](https://github.com/scauglog).
* [#454](https://github.com/ruby-grape/grape-swagger/pull/454): Include documented Hashes in documentation output - [@aschuster3](https://github.com/aschuster3).
* [#457](https://github.com/ruby-grape/grape-swagger/issues/457): Using camel case on namespace throws exception on add_swagger_documentation method - [@rayko](https://github.com/rayko).


### 0.21.0 (June 1, 2016)

#### Features

* [#413](https://github.com/ruby-grape/grape-swagger/pull/413): Move all model parsing logic to separate gems `grape-swagger-entity` and added representable parser `grape-swagger` - [@Bugagazavr](https://github.com/Bugagazavr).
* [#434](https://github.com/ruby-grape/grape-swagger/pull/434): Add summary to the operation object generator to be more compliant with [OpenAPI v2](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#operation-object) - [@aschuster3](https://github.com/aschuster3).
* [#441](https://github.com/ruby-grape/grape-swagger/pull/441): Accepting `String`, `lambda` and `proc` for `host` and `base_path` - [@LeFnord](https://github.com/LeFnord).

#### Fixes

* [#416](https://github.com/ruby-grape/grape-swagger/pull/416): Support recursive models - [@lest](https://github.com/lest).
* [#419](https://github.com/ruby-grape/grape-swagger/pull/419): Replaced github ref to rubygems for external gems - [@Bugagazavr](https://github.com/Bugagazavr).
* [#420](https://github.com/ruby-grape/grape-swagger/pull/420): Raise SwaggerSpec exception if swagger spec isn't satisfied, when no parser for model is registered or response model is empty - [@Bugagazavr](https://github.com/Bugagazavr).
* [#438](https://github.com/ruby-grape/grape-swagger/pull/438): Route version was missing in :options passed to PathString, so Endpoint.path_and_definitions_objects wasn't returning a versioned path when required - [@texpert](https://github.com/texpert).


### 0.20.3 (May 9, 2016)

#### Features

* [#407](https://github.com/ruby-grape/grape-swagger/issues/407): Added support for Grape 0.15.x and 0.16.x - [@dblock](https://github.com/dblock).
* [#406](https://github.com/ruby-grape/grape-swagger/pull/406): Force usage of entities for response definition [issue #385](https://github.com/ruby-grape/grape-swagger/issues/385) - [@LeFnord](https://github.com/LeFnord).
* [#405](https://github.com/ruby-grape/grape-swagger/pull/405), [#403](https://github.com/ruby-grape/grape-swagger/issues/403): Added version support matrix - [@LeFnord](https://github.com/LeFnord).
* [#408](https://github.com/ruby-grape/grape-swagger/pull/408): Added support for `HEAD` endpoints - [@Bugagazavr](https://github.com/Bugagazavr).
* [#408](https://github.com/ruby-grape/grape-swagger/pull/411): Added support for `OPTIONS` endpoints - [@Bugagazavr](https://github.com/Bugagazavr).

#### Fixes

* [#399](https://github.com/ruby-grape/grape-swagger/pull/399), [#395](https://github.com/ruby-grape/grape-swagger/issues/395): Make param description optional - [@LeFnord](https://github.com/LeFnord).


### 0.20.2 (April 22, 2016)

#### Fixes

* [#394](https://github.com/ruby-grape/grape-swagger/pull/394): Removed overiding default through example - [@LeFnord](https://github.com/LeFnord).
* [#393](https://github.com/ruby-grape/grape-swagger/pull/393): Properly handle header parameters - [@wleeper](https://github.com/wleeper).
* [#389](https://github.com/ruby-grape/grape-swagger/pull/389): Respect X-Forwarded-Host - [@edvakf](https://github.com/edvakf).


### 0.20.1 (April 17, 2016)

#### Features

* [#382](https://github.com/ruby-grape/grape-swagger/pull/382): Made schemes optional - [@wleeper](https://github.com/wleeper).
* [#381](https://github.com/ruby-grape/grape-swagger/pull/381): Added entity property description when property documentation desc option is present - [@elciok](https://github.com/elciok).

#### Fixes

* [#383](https://github.com/ruby-grape/grape-swagger/pull/383): Fixed support for Grape 0.12.0 through 0.14.0 - [@LeFnord](https://github.com/LeFnord).


### 0.20.0 (April 9, 2016)

#### Features

* [#336](https://github.com/ruby-grape/grape-swagger/pull/336): Added Swagger 2.0 support - [@LeFnord](https://github.com/LeFnord).
* [#371](https://github.com/ruby-grape/grape-swagger/pull/371): Added param type `body` handling - [@LeFnord](https://github.com/LeFnord).
* [#367](https://github.com/ruby-grape/grape-swagger/pull/367): Set default `type: Integer` and `required: true` for path params, if they weren't specified inside the `params` block as required - [@LeFnord](https://github.com/LeFnord).
* [#365](https://github.com/ruby-grape/grape-swagger/pull/365): Fixed passing markdown with redcarpet even with nil description and detail - [@LeFnord](https://github.com/LeFnord).
* [#358](https://github.com/ruby-grape/grape-swagger/pull/358): Removed `allowMultiple` property from params, added `format` to definition property and renamed `defaultValue` to `default` - [@LeFnord](https://github.com/LeFnord).
* [#356](https://github.com/ruby-grape/grape-swagger/pull/356): Added `consumes` - [@LeFnord](https://github.com/LeFnord).
* [#354](https://github.com/ruby-grape/grape-swagger/pull/354): Fixed setting of `base_path` and `host`, added possibility to configure the setting of `version` and `base_path` in documented path and `operationId` - [@LeFnord](https://github.com/LeFnord).
* [#353](https://github.com/ruby-grape/grape-swagger/pull/353), [#352](https://github.com/ruby-grape/grape-swagger/pull/353): Fixed exception with routes having a dynamic `:section` - [@LeFnord](https://github.com/LeFnord).


### 0.10.5 (April 12, 2016)

* [#344](https://github.com/ruby-grape/grape-swagger/pull/344): Namespace based tag included in Swagger JSON - [@LeFnord](https://github.com/LeFnord).


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
* [#110](https://github.com/ruby-grape/grape-swagger/pull/110), [#111](https://github.com/ruby-grape/grape-swagger/pull/111): Added `responseModel` support - [@bagilevi](https://github.com/bagilevi).
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
