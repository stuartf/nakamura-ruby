require 'rubygems'
require 'rake/clean'
require 'rubygems/package_task'

spec = Gem::Specification.new do |s|
  s.authors = "Sakai Project"
  s.email = "oae-dev@collab.sakaiproject.org"
  s.homepage = "http://sakaiproject.org"
  s.platform = Gem::Platform::RUBY
  s.summary = "Ruby library for interacting with Sakai Nakamura."
  s.name = 'nakamura'
  s.version = '0.13'
  s.requirements << 'none'
  s.require_path = 'lib'
  s.files = FileList['lib/**/*.rb']
  s.description = "Ruby library for interacting with Sakai Nakamura. Provides convenience methods for adding users and groups and other similar tasks."
end

  spec.add_dependency('json', '>=1.6.3')

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :default => [:gem]

CLEAN << "pkg/"
