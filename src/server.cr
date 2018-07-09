require "kemal"
require "file_utils"
require "json"
require "http/client"
require "logger"
require "db"
require "pg"
require "./util"
require "./github_client"
require "./github_hook"
require "./ci"

Repo = DB.open ENV["DATABASE_URL"]

get "/" do
  render "src/views/index.ecr", "src/views/layouts/layout.ecr"
end

record Project, id = "", kind = "", name = "", owner = "", link = "", result_count : Int64 = 0

get "/projects" do
  projects = [] of Project

  Repo.query(<<-SQL) do |rs|
    SELECT projects.id, kind, name, owner, link, COUNT(DISTINCT(results.id))
    FROM projects
    JOIN results
      ON results.project_id = projects.id
    GROUP BY projects.id
    LIMIT 100
  SQL
    rs.each do
      projects << Project.new(
        rs.read(String),
        rs.read(String),
        rs.read(String),
        rs.read(String),
        rs.read(String),
        rs.read(Int64),
      )
    end
  end

  render "src/views/projects.ecr", "src/views/layouts/layout.ecr"
end

get "/faq" do
  render "src/views/faq.ecr", "src/views/layouts/layout.ecr"
end

record Build, id = "", url = "", name = "", updated_at = Time.now, number = "", exit_status = 0

get "/projects/:project_id/builds" do |env|
  id = env.params.url["project_id"]
  builds = [] of Build

  Repo.query(<<-SQL, id) do |rs|
    SELECT
      id,
      hook_data->'pull_request'->>'html_url',
      hook_data->'pull_request'->'head'->'repo'->>'full_name',
      created_at,
      hook_data->'pull_request'->>'number',
      exit_status
    FROM results WHERE project_id = $1 LIMIT 100
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

  render "src/views/builds.ecr", "src/views/layouts/layout.ecr"
end

get "/builds" do
  builds = [] of Build

  Repo.query(<<-SQL) do |rs|
    SELECT
      id,
      hook_data->'pull_request'->>'html_url',
      hook_data->'pull_request'->'head'->'repo'->>'full_name',
      created_at,
      hook_data->'pull_request'->>'number',
      exit_status
    FROM results LIMIT 100
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

  render "src/views/builds.ecr", "src/views/layouts/layout.ecr"
end

get "/builds/:id" do |env|
  id = env.params.url["id"]
  pr_url = ""
  logs = [] of LogLine
  exit_status = 0

  pr_url, exit_status = Repo.query_one(<<-SQL, id, as: {String, Int32})
    SELECT hook_data->'pull_request'->>'html_url' AS url, exit_status
    FROM results WHERE id = $1 LIMIT 1
  SQL
  Repo.query "SELECT time, kind, line FROM logs WHERE result_id = $1", id do |rs|
    rs.each do
      logs << LogLine.new(rs.read(Time), rs.read(String), rs.read(String))
    end
  end

  duration = 0
  if logs.size > 0
    duration = (logs.last.time - logs.first.time)
  end

  render "src/views/build_id.ecr", "src/views/layouts/layout.ecr"
end

post "/github-webhook" do |env|
  if body_io = env.request.body
    GitHubHook.handle(body_io.gets_to_end, env.request.headers["X-GitHub-Event"])
    "OK"
  end
end

Kemal.run
