## Contributing

I value any contribution to minitar you can provide: a bug report, a feature
request, or code contributions.

As minitar is a mature codebase, there are a few guidelines:

*   Code changes *will not* be accepted without tests. The test suite is
    written with [Minitest](https://github.com/seattlerb/minitest).
*   Match my coding style.
*   Use a thoughtfully-named topic branch that contains your change. Rebase
    your commits into logical chunks as necessary.
*   Use [quality commit messages](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).
*   Do not change the version number; when your patch is accepted and a release
    is made, the version will be updated at that point.
*   Submit a GitHub pull request with your changes.
*   New or changed behaviours require new or updated documentation.

### Test Dependencies

minitar uses Ryan Davis’s [Hoe](https://github.com/seattlerb/hoe) to manage
the release process, and it adds a number of rake tasks. You will mostly be
interested in:

    $ rake

which runs the tests the same way that:

    $ rake test
    $ rake travis

will do.

To assist with the installation of the development dependencies for minitar, I
have provided the simplest possible Gemfile pointing to the (generated)
`minitar.gemspec` file. This will permit you to do:

    $ bundle install

to get the development dependencies. If you aleady have `hoe` installed, you
can accomplish the same thing with:

    $ rake newb

This task will install any missing dependencies, run the tests/specs, and
generate the RDoc.

### Workflow

Here's the most direct way to get your work merged into the project:

*   Fork the project.
*   Clone down your fork (`git clone git://github.com/<username>/minitar.git`).
*   Create a topic branch to contain your change (`git checkout -b
    my_awesome_feature`).
*   Hack away, add tests. Not necessarily in that order.
*   Make sure everything still passes by running `rake`.
*   If necessary, rebase your commits into logical chunks, without errors.
*   Push the branch up (<tt>git push origin my\_awesome\_feature</tt>).
*   Create a pull request against halostatue/minitar and describe what your
  change does and the why you think it should be merged.

### Contributors

* Austin Ziegler created minitar, which is based on work originally performed
  by Mauricio Fernández for rpa-base.
