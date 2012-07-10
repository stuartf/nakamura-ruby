Usage
=====

Just run `gem install nakamura` then in your script `require 'nakamura'`.

Then see the generated documentation at http://rubydoc.info/gems/nakamura/

Building a new gem
==================

    rake clean
    rake

Publishing to rubygems
======================

    gem push pkg/nakamura-x.y.z.gem # x.y.z is the version from Rakefile
                                    # also you'll have to be listed as an
                                    # owner at http://rubygems.org/gems/nakamura
    git tag -s x.y.z
    git push sakaiproject --tags
