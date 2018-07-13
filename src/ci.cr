module Scylla
  struct CI
    extend Util

    NIX_BUILD_OPTIONS = {
      "allow-import-from-derivation" => true,
      "auto-optimise-store"          => true,
      "enforce-determinism"          => true,
      "fallback"                     => true,
      "http2"                        => true,
      "keep-build-log"               => true,
      "max-build-log-size"           => 100000,
      "restrict-eval"                => true,
      "show-trace"                   => true,
      "timeout"                      => 60,
    }

    def self.build_from_git(clone_url : String, sha : String, id : String)
      dest = "ci/#{clone_url.gsub(/\W+/, "_")}-#{sha}"
      FileUtils.rm_rf dest
      FileUtils.mkdir_p dest

      clone = "#{dest}"
      record_log = ->(kind : String, line : String) {
        Log.insert(Time.now, kind, line, id)
      }

      # sh("git", "clone", clone_url, clone, &record_log)
      # sh("git", "-C", clone, "checkout", sha, &record_log)
      options = NIX_BUILD_OPTIONS.map { |k, v| ["--option", k, v.to_s] }.flatten
      args = ["build", "--no-link", "-f", "./ci.nix"] + options
      sh("nix", args, &record_log)
    end
  end
end
