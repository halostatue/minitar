# minitar

- home :: https://github.com/halostatue/minitar
- issues :: https://github.com/halostatue/minitar/issues
- code :: https://github.com/halostatue/minitar/

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

[semver]: http://semver.org/
