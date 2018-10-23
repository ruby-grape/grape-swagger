# Releasing Grape-Swagger

There are no particular rules about when to release grape-swagger. Any co-maintainer is encouraged to release bug fixes frequently, features not so frequently and breaking API changes rarely.

### Release

Run tests, check that all tests succeed locally.

```
bundle install
rake
```

Check that the last build succeeded in [Travis CI](https://travis-ci.org/ruby-grape/grape-swagger) for all supported platforms.

Change "Next" in [CHANGELOG.md](CHANGELOG.md) to the current date.

```
### 0.7.2 (February 6, 2014)
```

Remove the lines with "Your contribution here.", since there will be no more contributions to this release.

Commit your changes.

```
git add CHANGELOG.md lib/grape-swagger/version.rb
git commit -m "Preparing for release, 0.7.2."
git push origin master
```

Release.

```
$ rake release

grape-swagger 0.7.2 built to pkg/grape-swagger-0.7.2.gem.
Tagged v0.7.2.
Pushed git commits and tags.
Pushed grape-swagger 0.7.2 to rubygems.org.
```

### Prepare for the Next Version

Increment the minor version, the third number, modify [lib/grape-swagger/version.rb](lib/grape-swagger/version.rb). For example, change `0.7.1` to `0.7.2`. Major versions are incremented in pull requests that require it.

Add the next release to [CHANGELOG.md](CHANGELOG.md).

```
### 0.7.3 (Next)

#### Features

* Your contribution here.

#### Fixes

* Your contribution here.
```

Commit your changes.

```
git add CHANGELOG.md lib/grape-swagger/version.rb
git commit -m "Preparing for next developer iteration, 0.7.3."
git push origin master
```

### Make an Announcement

Make an announcement on the [ruby-grape@googlegroups.com](mailto:ruby-grape@googlegroups.com) mailing list. The general format is as follows.

```
Grape-Swagger 0.7.2 has been released.

There were 8 contributors to this release, not counting documentation.

Please note the breaking API change in ...

[copy/paste CHANGELOG here]

```
