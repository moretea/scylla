module Scylla
  struct CI
    extend Util

    def self.build_from_git(clone_url : String, sha : String, id : String)
      root = self.root(clone_url, sha)
      sh("./bin/run-ci", root, clone_url, sha) { |kind, line|
        Log.insert(Time.now, kind, line, id)
      }
    end

    def self.root(clone_url : String, sha : String)
      "ci/#{clone_url.gsub(/\W+/, "_")}-#{sha}"
    end

    def self.nix_logs(clone_url : String, sha : String) : Array(String)
      logs = [] of String

      sh("nix", "log", "#{root(clone_url, sha)}/result") { |_, line|
        logs << line
      }

      logs
    rescue
      [] of String
    end
  end
end
