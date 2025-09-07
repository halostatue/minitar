# Contributing

Contribution to minitar is encouraged: bug reports, feature requests, or code
contributions. There are a few DOs and DON'Ts that should be followed:

- DO:

  - Keep the coding style that already exists for any updated Ruby code (support
    or otherwise). I use [Standard Ruby][standardrb] for linting and formatting.

  - Use thoughtfully-named topic branches for contributions. Rebase your commits
    into logical chunks as necessary.

  - Use [quality commit messages][qcm] for each commit (minitar uses a rebase
    merge strategy). Ensure that each commit includes the required Developer
    Certificate of Origin [sign-off][sign-off].

  - Add your name or GitHub handle to `CONTRIBUTORS.md` and a record in the
    `CHANGELOG.md` as a separate commit from your main change. (Follow the style
    in the `CHANGELOG.md` and provide a link to your PR.)

  - Add or update tests as appropriate for your change. The test suite is
    written with [minitest][minitest].

  - Add or update documentation as appropriate for your change. The
    documentation is RDoc; mime-types does not use extensions that may be
    present in alternative documentation generators.

- DO NOT:

  - Modify `VERSION` in `lib/minitar/version.rb`. When your patch is accepted
    and a release is made, the version will be updated at that point.

  - Modify `minitar.gemspec`; it is a generated file. (You _may_ use
    `rake gemspec` to regenerate it if your change involves metadata related to
    gem itself).

  - Modify the `Gemfile`.

## LLM-Generated Contribution Policy

minitar-cli accepts only issues or pull requests that are well understood by the
submitter and that, especially for pull requests, the developer can attest to
the [Developer Certificate of Origin][dco] for each pull request (see
[LICENCE](LICENCE.md)).

If LLM assistance is used in writing pull requests, this must be documented in
the commit message and pull request. If there is evidence of LLM assistance
without such declaration, the pull request **will be declined**.

Any contribution (bug, feature request, or pull request) that uses unreviewed
LLM output will be rejected.

For an example of how this should be done, see [#151][pr-151] and its
[associated commits][pr-151-commits].

## Test

minitar uses Ryan Davis's [Hoe][Hoe] to manage the release process, and it adds
a number of rake tasks. You will mostly be interested in `rake`, which runs
tests in the same way that `rake test` does.

To assist with the installation of the development dependencies for minitar, I
have provided the simplest possible Gemfile pointing to the (generated)
`minitar.gemspec` file. This will permit you to use `bundle install` to install
the development dependencies.

You can run tests with code coverage analysis by running `rake coverage`.

### Test Helpers

Minitar includes a number of custom test assertions, constants, and test utility
methods that are useful for writing tests. These are maintained through modules
defined in `test/support`.

#### Fixture Utilities

Minitar uses fixture tarballs in various tests, referenced by their base name
(`test/fixtures/tar_input.tar.gz` becomes `tar_input`, etc.). There are two
utility methods:

- `Fixture(name)`: This returns the `Pathname` object for the full path of the
  named fixture tarball or `nil` if the named fixture does not exist.

- `open_fixture(name)`: This retrieves the named fixture and opens it. If the
  fixture ends with `.gz` or `.tgz`, it will be opened with a
  `Zlib::GZipReader`. A block may be provided to ensure that the fixture is
  automatically closed.

#### Header Assertions and Utilities

Tar headers need to be built and compared in an exacting way, even for tests.

There are two assertions:

- `assert_headers_equal(expected, actual)`: This compares headers by field order
  verifying that each field in `actual` is supposed to match the corresponding
  field in `expected`.

  `expected` must be a string representation of the expected header and this
  assertion calls `#to_s` on the `actual` value so that both `PosixHeader` and
  `PaxHeader` instances are converted to string representations for comparison.

- `assert_modes_equal(expected, actual, filename)`: This compares the expected
  octal mode string of `expected` against `actual` for a given `filename`. The
  modes must be integer values. This assertion is skipped on Windows.

There are several other helper methods available for working with headers:

- `build_tar_file_header(name, prefix, mode, length)`: This builds a header for
  a file `prefix/name` with `mode` and `length` bytes. `name` is limited to 100
  bytes and `prefix` is limited to 155 bytes.

- `build_tar_dir_header(name, prefix, mode)`: This builds a header for a
  directory `prefix/name` with `mode`. `name` is limited to 100 bytes and
  `prefix` is limited to 155 bytes.

- `build_tar_symlink_header(name, prefix, mode, target)`: This builds a header
  for a symbolic link of `prefix/name` to `target` where the symbolic link has
  `mode`. `name` is limited to 100 bytes and `prefix` is limited to 155 bytes.

- `build_tar_pax_header(name, prefix, bytes)`: This builds a header block for a
  PAX extension at `name/prefix` with `content_size` bytes.

- `build_header(type, name, prefix, size, mode, link = "")`: This builds an
  otherwise unspecified header type. If you find yourself using this, it is
  recommended to add a new `build_*_header` helper method.

#### Tarball Helpers

Minitar has several complex assertions and utilities to work with both in-memory
and on-disk tarballs. These work using two concepts, file hashes (`file_hash`)
and workspaces (`workspace`).

##### File Hashes (`file_hash`)

Many of these consume or produce a `file_hash`, which is a hash of
`{filename => content}` where the tarball will be produced with such that each
entry in the `file_hash` becomes a file named `filename` with the data
`content`.

As an example, `Minitar::TestHelpers` has a `MIXED_FILENAME_SCENARIOS` constant
that is a `file_hash`:

```ruby
MIXED_FILENAME_SCENARIOS = {
  "short.txt" => "short content",
  "medium_length_filename_under_100_chars.txt" => "medium content",
  "dir1/medium_filename.js" => "medium nested content",
  "#{"x" * 120}.txt" => "long content",
  "nested/dir/#{"y" * 110}.css" => "long nested content"
}.freeze
```

This will produce a tarball that looks like:

```
short.txt
medium_length_filename_under_100_chars.txt
dir1/medium_filename.js
x[118 more 'x' characters...]x
nested/dir/y[108 more y' characters...]y.css
```

Each file will contain the text as the content.

If the `content` is `nil`, this will be ignored for in-memory tarballs, but will
be created as empty directory entries for on-disk tarballs.

##### Workspace (`workspace`)

A workspace is a temporary directory used for on-disk tests. It is created with
the `workspace` utility method (see below) and must be passed a block where all
setup and tests will be run.

At most one `workspace` may be used per test method.

##### Assertions

There are five assertions:

- `assert_tar_structure_preserved(original_files, extracted_files)`: This is
  used primarily with string tarballs. Given two `file_hash`es representing
  tarball contents (the original files passed to `create_tar_string` and the
  extracted files returned from `extract_tar_string`), it ensures that all files
  from the original contents are present and that no additional files have been
  added in the process.

- `assert_files_extracted_in_workspace`: Can only be run in a `workspace` and
  the test tarball must have been both created and extracted. This ensures that
  all of the files and/or directories expected have been extracted and that the
  contents of files match. File modes are ignored for this assertion.

- `refute_file_path_duplication_in_workspace`: Can only be run in a `workspace`
  and the test tarball must have been both created and extracted. This is used
  to prevent regression of [#62][issue-62] with explicit file tests. This only
  needs to be called after unpacking with Minitar methods.

- `assert_extracted_files_match_source_files_in_workspace`: Can only be run in a
  `workspace` and the test tarball must have been both created and extracted.
  This ensures that there are no files missing or added in the `target`
  directory that should are not also be in the `source` directory. This does no
  contents comparison.

- `assert_file_modes_match_in_workspace`: Can only be run in a `workspace` and
  the test tarball must have been both created and extracted. This ensures that
  all files have the same modes between source and target. This is skipped on
  Windows.

##### In-Memory Tarball Utilities

- `create_tar_string`: Given a `file_hash`, this creates a string containing the
  output of `Minitar::Output.open` and `Minitar.pack_as_file`.

- `extract_tar_string`: Given the string output of `create_tar_string` (or any
  uncompressed tarball string), uses `Minitar::Input.open` to read the files
  into a hash of `{filename => content}`.

- `roundtrip_tar_string`: calls `create_tar_string` on a `file_hash` and
  immediately calls `extract_tar_string`, returning a processed `file_hash`.

##### On-Disk Workspace Tarball Utilities

- `workspace`: Prepares a temporary directory for working with tarballs on disk
  inside the block that must be provided. If given a hash of files, calls
  `prepare_files`. The workspace directory will be removed after the block
  finishes executing.

  A workspace has a `source` directory, a `target` directory`, and the`tarball`
  which will be created from the prepared files.

  All other utility methods _must_ be run inside of a `workspace` block.

- `prepare_workspace`: creates a file structure in the workspace source
  directory given the `{filename => content}` hash. For on-disk file structures,
  `{directory_name => nil}` can be used to create empty directories. Directory
  names will be created automatically for nested filenames.

- `gnu_tar_create_in_workspace`, `gnu_tar_extract_in_workspace`, and
  `gnu_tar_list_in_workspace` work with the workspace tarball using GNU tar
  (either `tar` or `gtar`). GNU tar tests will be skipped if GNU tar is not
  available.

- `minitar_pack_in_workspace`, `minitar_unpack_in_workspace` use `Minitar.pack`
  and `Minitar.unpack`, respectively, to work with the workspace tarball.

- `minitar_writer_create_in_workspace` uses `Minitar::Writer` to create the
  workspace tarball.

## Workflow

Here's the most direct way to get your work merged into the project:

- Fork the project.
- Clone your fork (`git clone git://github.com/<username>/minitar.git`).
- Create a topic branch to contain your change
  (`git checkout -b my_awesome_feature`).
- Hack away, add tests. Not necessarily in that order.
- Make sure everything still passes by running `rake`.
- If necessary, rebase your commits into logical chunks, without errors.
- Push the branch up (`git push origin my_awesome_feature`).
- Create a pull request against halostatue/minitar and describe what your change
  does and the why you think it should be merged.

[dco]: licences/dco.txt
[hoe]: https://github.com/seattlerb/hoe
[issue-62]: https://github.com/halostatue/minitar/issues/62
[minitest]: https://github.com/seattlerb/minitest
[pr-151-commits]: https://github.com/halostatue/minitar/pull/151/commits
[pr-151]: https://github.com/halostatue/minitar/pull/151
[qcm]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[sign-off]: LICENCE.md#developer-certificate-of-origin
[standardrb]: https://github.com/standardrb/standard
