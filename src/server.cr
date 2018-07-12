require "file_utils"
require "json"
require "http/client"
require "logger"
require "db"

require "kemal"
require "pg"

require "./util"
require "./github_client"
require "./github_hook"
require "./ci"
require "./sql"

module Scylla
  L    = Logger.new(STDOUT, level: Logger::DEBUG)
  Repo = DB.open ENV["DATABASE_URL"]
end

get "/" do
  render "src/views/index.ecr", "src/views/layouts/layout.ecr"
end

get "/projects" do
  projects = Scylla::Project.recent(100)
  render "src/views/projects.ecr", "src/views/layouts/layout.ecr"
end

get "/faq" do
  render "src/views/faq.ecr", "src/views/layouts/layout.ecr"
end

get "/projects/:project_id/builds" do |env|
  id = env.params.url["project_id"]
  builds = Scylla::Result.recent_for_project(id)

  render "src/views/builds.ecr", "src/views/layouts/layout.ecr"
end

get "/builds" do
  builds = Scylla::Result.recent
  render "src/views/builds.ecr", "src/views/layouts/layout.ecr"
end

get "/builds/:id" do |env|
  id = env.params.url["id"]
  info = Scylla::Result.info_for_result(id)
  logs = Scylla::Log.all_for_result(id)

  duration = 0
  if logs.size > 0
    duration = (logs.last.time - logs.first.time)
  end

  render "src/views/build_id.ecr", "src/views/layouts/layout.ecr"
end

post "/github-webhook" do |env|
  if body_io = env.request.body
    Scylla::GitHubHook.handle(body_io.gets_to_end, env.request.headers["X-GitHub-Event"])
    "OK"
  end
end

Kemal.run
