L = Logger.new(STDOUT, level: Logger::DEBUG)
record LogLine, time = Time.now, kind = "unknown", line = ""

struct CI
  extend Util
  LOG_QUERY = <<-SQL
    INSERT INTO logs
      (time, kind, line, result_id)
    VALUES
      ($1, $2, $3, $4);
  SQL

  def self.build_from_git(clone_url : String, sha : String, id : String)
    dest = "ci/#{clone_url.gsub(/\W+/, "_")}-#{sha}"
    FileUtils.rm_rf dest
    FileUtils.mkdir_p dest

    clone = "#{dest}/clone"
    record_log = ->(kind : String, line : String) {
      Repo.exec(LOG_QUERY, Time.now, kind, line, id)
    }

    sh("git", "clone", clone_url, clone, &record_log)
    sh("git", "-C", clone, "checkout", sha, &record_log)
    sh("nix-build", "--no-out-link", "--show-trace", "./#{dest}/clone/ci.nix", &record_log)
  end
end
