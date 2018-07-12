module Scylla
  struct Log
    property time, kind, line, result_id

    def initialize(@time : Time, @kind : String, @line : String, @result_id : String)
    end

    def initialize(@time : Time, @kind : String, @line : String, @result_id = -1)
    end

    def self.insert(time : Time, kind : String, line : String, result_id : String)
      Repo.exec(<<-SQL, Time.now, kind, line, result_id)
        INSERT INTO logs
          (time, kind, line, result_id)
        VALUES
          ($1, $2, $3, $4);
      SQL
    end

    def self.all_for_result(result_id : String)
      logs = [] of Log

      Repo.query(<<-SQL, result_id) do |rs|
        SELECT time, kind, line FROM logs WHERE result_id = $1
      SQL
        rs.each do
          logs << new(rs.read(Time), rs.read(String), rs.read(String))
        end
      end

      logs
    end
  end

  struct Project
    property id, kind, name, owner, link, result_count

    def initialize(@id : String, @kind : String, @name : String, @owner : String, @link : String, @result_count : Int64)
    end

    def self.recent(n = 100)
      projects = [] of Project

      Repo.query(<<-SQL, n) do |rs|
        SELECT projects.id, kind, name, owner, link, COUNT(DISTINCT(results.id))
        FROM projects
        JOIN results
          ON results.project_id = projects.id
        GROUP BY projects.id
        LIMIT $1
      SQL
        rs.each do
          projects << new(
            rs.read(String),
            rs.read(String),
            rs.read(String),
            rs.read(String),
            rs.read(String),
            rs.read(Int64),
          )
        end
      end

      projects
    end
  end

  struct Result
    property id, hook_data, exit_status, created_at, finished_at, project_id

    def initialize(@id : String, @hook_data : String, @exit_status : Int32, @created_at : Time, @finished_at : Time, @project_id : String)
    end

    record Info, pr_url : String, exit_status : (Nil | Int32)

    def self.info_for_result(result_id : String)
      pr_url, exit_status = Repo.query_one(<<-SQL, result_id, as: {String, Int32})
        SELECT hook_data->'pull_request'->>'html_url' AS url, exit_status
        FROM results WHERE id = $1 LIMIT 1
      SQL
      Info.new(pr_url, exit_status)
    end

    record Build, id = "", url = "", name = "", updated_at = Time.now, number = "", exit_status = 0

    def self.recent_for_project(project_id : String, n = 100)
      builds = [] of Build

      Repo.query(<<-SQL, project_id, n) do |rs|
        SELECT
          id,
          hook_data->'pull_request'->>'html_url',
          hook_data->'pull_request'->'head'->'repo'->>'full_name',
          created_at,
          hook_data->'pull_request'->>'number',
          exit_status
        FROM results WHERE project_id = $1 LIMIT $2
      SQL
        rs.each do
          builds << Build.new(
            rs.read(String),
            rs.read(String),
            rs.read(String),
            rs.read(Time),
            rs.read(String),
            rs.read(Int32),
          )
        end

        builds
      end
    end

    def self.recent(n = 100)
      builds = [] of Build

      Repo.query(<<-SQL, n) do |rs|
        SELECT
          id,
          hook_data->'pull_request'->>'html_url',
          hook_data->'pull_request'->'head'->'repo'->>'full_name',
          created_at,
          hook_data->'pull_request'->>'number',
          exit_status
        FROM results LIMIT $1
      SQL
        rs.each do
          builds << Build.new(
            rs.read(String),
            rs.read(String),
            rs.read(String),
            rs.read(Time),
            rs.read(String),
            rs.read(Int32),
          )
        end
      end

      builds
    end
  end
end
