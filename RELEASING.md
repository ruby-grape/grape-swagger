# Releasing Grape-Swagger

There are no particular rules about when to release grape-swagger. Any co-maintainer is encouraged to release bug fixes frequently, features not so frequently and breaking API changes rarely.

### Release

Run tests locally and make sure they pass.

```
bundle install
rake
```

Make sure the "Next" section in [CHANGELOG.md](CHANGELOG.md) lists the changes for the release. A release with only placeholder notes is refused. Keep at least one `* Your contribution here.` line in the section, because the workflow removes the placeholder lines and refuses a section that has none.

Dispatch the Release workflow from the `master` branch, either from the Actions tab or from the command line. Leave `version` empty to release the version in [lib/grape-swagger/version.rb](lib/grape-swagger/version.rb).

```
gh workflow run release.yml
```

The workflow:

- Validates the release and builds the gem.
- Publishes the gem to RubyGems through Trusted Publishing, so no API key is needed.
- Changes "Next" in [CHANGELOG.md](CHANGELOG.md) to the release version and the current date, and removes the "Your contribution here." lines.
- Tags the release, creates the GitHub Release, and pushes the commit to `master`.
- Bumps the version and opens the next "Next" section in [CHANGELOG.md](CHANGELOG.md).

The local Bundler release tasks (`rake release`, `release:rubygem_push`, and `release:source_control_push`) are disabled. They stop with a message that points to the workflow.

The `release` environment in GitHub requires an approval before the workflow publishes. Maintainers listed as reviewers approve the run.

### If a Release Fails

Do not merge anything into `master` while a release runs. If `master` moves before the gem is published, the release stops safely and a new dispatch starts clean. If it moves after publication, the gem is on RubyGems but the push fails with `Default branch advanced; start a new release`, leaving no tag, release commit, GitHub Release, or next version, and a new dispatch does not repair that. Recover from the artifacts the run preserved, following [Default Branch Advanced During Publication](https://github.com/dblock/ruby-gem-release/blob/master/docs/actions/release.md#default-branch-advanced-during-publication) in the ruby-gem-release documentation.

### One-time Setup

Maintainers set these up once before the first release:

- A RubyGems trusted publisher for `grape-swagger` that points to `ruby-grape/grape-swagger`, the `release.yml` workflow, and the `release` environment. The workflow is a reusable one, so also set the separate workflow repository owner and name fields to `dblock` and `ruby-gem-release`.
- A `release` environment in the repository settings, with required reviewers and a deployment branch rule that only allows `master`.
- Permission for the Actions token to push the release commit and tag to `master`.

Then dispatch the Release workflow once with `dry-run` enabled (`gh workflow run release.yml -f dry-run=true`). It checks the prerequisites, including Trusted Publishing, without publishing anything.

### Make an Announcement

Make an announcement on the [ruby-grape@googlegroups.com](mailto:ruby-grape@googlegroups.com) mailing list. The general format is as follows.

```
Grape-Swagger 2.2.0 has been released.

There were 8 contributors to this release, not counting documentation.

Please note the breaking API change in ...

[copy/paste CHANGELOG here]

```
