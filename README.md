# minitar

[![RubyGems Version][shield-gems]][rubygems] ![Coveralls][shield-coveralls]
[![Build Status][shield-ci]][ci-workflow]

- code :: <https://github.com/halostatue/minitar>
- issues :: <https://github.com/halostatue/minitar/issues>
- docs :: <https://halostatue.github.io/minitar/>
- changelog :: <https://github.com/halostatue/minitar/blob/main/CHANGELOG.md>

## Description

The minitar library is a pure-Ruby library that operates on POSIX tar(1) archive
files.

minitar (previously called Archive::Tar::Minitar) is based heavily on code
originally written by Mauricio Julio Fernández Pradier for the rpa-base project.

## Synopsis

Using minitar is easy. The simplest case is:

```ruby
require 'minitar'

# Packs everything that matches Find.find('tests').
# test.tar will automatically be closed by Minitar.pack.
Minitar.pack('tests', File.open('test.tar', 'wb'))

# Unpacks 'test.tar' to 'x', creating 'x' if necessary.
Minitar.unpack('test.tar', 'x')
```

A gzipped tar can be written with:

```ruby
  require 'zlib'
  # test.tgz will be closed automatically.
  Minitar.pack('tests', Zlib::GzipWriter.new(File.open('test.tgz', 'wb'))

  # test.tgz will be closed automatically.
  Minitar.unpack(Zlib::GzipReader.new(File.open('test.tgz', 'rb')), 'x')
```

As the case above shows, one need not write to a file. However, it will
sometimes require that one dive a little deeper into the API, as in the case of
StringIO objects. Note that I'm not providing a block with Minitar::Output, as
Minitar::Output#close automatically closes both the Output object and the
wrapped data stream object.

```ruby
begin
  sgz = Zlib::GzipWriter.new(StringIO.new(String.new))
  tar = Output.new(sgz)
  Find.find('tests') do |entry|
    Minitar.pack_file(entry, tar)
  end
ensure
  # Closes both tar and sgz.
  tar.close
end
```

## Minitar and Security

See [SECURITY](./SECURITY.md)

## minitar Semantic Versioning

The minitar library uses a [Semantic Versioning][semver] scheme with one change:

- When PATCH is zero (`0`), it will be omitted from version references.

[ci-workflow]: https://github.com/halostatue/minitar/actions/workflows/ci.yml
[coveralls]: https://coveralls.io/github/halostatue/minitar?branch=main
[rubygems]: https://rubygems.org/gems/minitar
[semver]: https://semver.org/
[shield-ci]: https://img.shields.io/github/actions/workflow/status/halostatue/minitar/ci.yml?style=for-the-badge "Build Status"
[shield-coveralls]: https://img.shields.io/coverallsCoverage/github/halostatue/minitar?style=for-the-badge
[shield-gems]: https://img.shields.io/gem/v/minitar?style=for-the-badge "Version"
