# frozen_string_literal: true

require "cr"

IMAGE = "ruby"
LATEST = "22.04-3.0"
ACTION = ENV["PUSH"] == "true" ? "--push" : ""

CACHE_DIR = "cache/docker"

# https://packages.ubuntu.com/jammy/ruby
UB_VERSION = {
  "20.04": "2.7",
  "22.04": "3.0",
  "24.04": "3.2"
}.freeze

# https://pkgs.alpinelinux.org/packages?name=ruby&branch=edge
AL_VERSION = {
  "edge": "3.3",
  "3.19": "3.2",
  "3.17": "3.1",
  "3.15": "3.0",
  "3.14": "2.7"
}.freeze

TMPL_VERSION = {
  "ubuntu": UB_VERSION,
  "alpine": AL_VERSION
}.freeze

IMAGE_SUPPORT = {
  # below info from Picture text recognition
  # https://hub.docker.com/_/alpine/tags?page=1&name=edge
  "alpine": [
    "linux/386",
    "linux/amd64",
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/arm64/v8",
    "linux/ppc64le",
    "linux/riscv64",
    "linux/s390x"
  ],
  # https://hub.docker.com/_/ubuntu/tags?page=1&name=22.04
  "ubuntu": [
    "linux/amd64",
    "linux/arm/v7",
    "linux/arm64/v8",
    "linux/ppc64le",
    "linux/riscv64",
    "linux/s390x"
  ]
}.freeze

REG_IMAGES = [
  "docker.io/initdc/#{IMAGE}",
  "ghcr.io/initdc/#{IMAGE}"
].freeze

Cr.run("mkdir -p #{CACHE_DIR}")

TMPL_VERSION.each do |tmpl_sym, version|
  tmpl = tmpl_sym.to_s
  tmpl_file = "Dockerfile.#{tmpl}"
  tmpl_content = IO.read(tmpl_file)
  version.each do |os_ver_sym, rb_ver|
    os_ver = os_ver_sym.to_s
    tag = "#{os_ver}-#{rb_ver}"
    dockerfile = "Dockerfile.#{tag}"
    content = tmpl_content.gsub("{version}", os_ver)

    Dir.chdir CACHE_DIR do
      IO.write(dockerfile, content)
      platform = IMAGE_SUPPORT[tmpl_sym].join(",")

      REG_IMAGES.each do |reg_img|
        build_cmd = "docker buildx build --platform #{platform} -t #{reg_img}:#{tag} -f #{dockerfile} . #{ACTION}"

        puts build_cmd
        Cr.run(build_cmd)

        next unless tag == LATEST

        latest_cmd = "docker buildx build --platform #{platform} -t #{reg_img}:latest -f #{dockerfile} . #{ACTION}"

        puts latest_cmd
        Cr.run(latest_cmd)
      end
    end
  end
end
