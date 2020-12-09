# Release - a HAProxy release
# Build   - our docker image for a corresponding release
#

HAPROXY_GIT_URL = "http://git.haproxy.org/git/haproxy-%s.git"

# Supported versions per the table on the haproxy.org homepage
HAPROXY_MAJOR_VERSIONS = %w(1.8 2.0 2.1 2.2 2.3)

# HAProxy versions we have built.
HAPROXY_BUILDS = %x(git tag).split

EXHAUSTIVE = ARGV.first == "--all"

def haproxy_git_url major
  HAPROXY_GIT_URL % major
end

def haproxy_builds_for major
  re_ver = Regexp.quote(major + ".")

  versions = HAPROXY_BUILDS.grep /^#{re_ver}/

  versions.sort_by { |v| Gem::Version.new(v) }
end

# All releases from the HAProxy project for a given major version.
# The leading "v" in the version string vX.Y.Z is removed.
def haproxy_releases_for major
  refs_and_tags = %x(git ls-remote --tags -q --refs #{haproxy_git_url(major)} v#{major}.*)

  versions = refs_and_tags.split(/\n/).map { |r| r.sub(%r{^.*refs/tags/v}, "") }

  versions.sort_by { |v| Gem::Version.new(v) }
end

def pending_builds major
  builds   = haproxy_builds_for major
  releases = haproxy_releases_for major

  releases - builds
end

def build version
  update
  build_haproxy version
  tag
  push
end

def update
  update_lib :libslz
  update_lib :openssl
  update_lib :pcre
end

HAPROXY_MAJOR_VERSIONS.each do |major|

  if EXHAUSTIVE
    pending_builds(major).each do |version|
      puts "A build is required for HAProxy version %s" % version
    end

  else
    puts "Latest %s release is %s, have %s (%s)" % [
      major, haproxy_releases_for(major).last, haproxy_builds_for(major).last,
      haproxy_releases_for(major).last == haproxy_builds_for(major).last ? "OK" : "FAIL"
    ]
  end
end

