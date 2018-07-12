module Scylla
  struct CI
    extend Util

    def self.build_from_git(clone_url : String, sha : String, id : String)
      dest = "ci/#{clone_url.gsub(/\W+/, "_")}-#{sha}"
      FileUtils.rm_rf dest
      FileUtils.mkdir_p dest

      clone = "#{dest}"
      record_log = ->(kind : String, line : String) {
        Log.insert(Time.now, kind, line, id)
      }

      sh("git", "clone", clone_url, clone, &record_log)
      sh("git", "-C", clone, "checkout", sha, &record_log)
      sh("nix-build", "-vv", "-no-out-link", "--show-trace", "./#{dest}/ci.nix", &record_log)
    end
  end
end
