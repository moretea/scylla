require "kemal"
require "file_utils"
require "json"
require "http/client"

module Util
  def sh(*cmd)
    executable = ""
    args = [] of String

    cmd.each_with_index do |a, i|
      if i == 0
        executable = a
      else
        args << a
      end
    end

    stdout = [] of String
    stderr = [] of String

    pp({executable => args})

    Process.run(executable, args: args) do |status|
      status.output.each_line do |line|
        stdout << line
        print line
      end
      status.error.each_line.each do |line|
        stderr << line
        print line
      end
    end

    unless $?.success?
      raise "Failure while running #{executable}"
    end

    [stdout, stderr, $?]
  end
end

struct GithubClient
  def self.prs(owner : String, name : String)
    res = HTTP::Client.post(
      "https://api.github.com/graphql",
      headers: HTTP::Headers{
        "Authorization" => "bearer d6848acadca6e1277a2ec213e052b0e9c930e897",
      },
      body: {
        "query" => %(
          {
            repository(owner: "#{owner}", name: "#{name}") {
              pullRequests(states: OPEN, last: 1) {
                nodes {
                  mergeable
                  headRefOid
                  publishedAt
                }
              }
            }
          }
        ),
      }.to_json
    )

    pp res
  end
end

struct CI
  extend Util

  def self.build(project : String, branch : String)
    FileUtils.mkdir_p "ci"
    dest = "ci/#{project.gsub(/\W+/, "_")}-#{branch}-#{Random.new.hex(16)}"
    pp sh("git", "clone", "--single-branch", "-b", branch, project, dest)
    pp sh("nix-build", "--show-trace", "./#{dest}/ci.nix")
  rescue ex
    pp ex
  end
end

get "/" do
  # render "src/views/index.ecr"
end

post "/github-webhook" do |env|
  pp env
  body = env.request.body
  puts body.gets_to_end if body
end

struct GitHubHook
  struct Hook
    struct LastResponse
      JSON.mapping(
        code: (Int64 | Nil),
        status: String,
        message: String | Nil,
      )
    end

    JSON.mapping(
      type: String,
      id: Int64,
      name: String,
      active: Bool,
      events: Array(String),
      config: Hash(String, String),
      updated_at: Time,
      created_at: Time,
      url: String,
      test_url: String,
      ping_url: String,
      last_response: LastResponse,
    )
  end

  struct Repository
    struct License
      JSON.mapping(
        key: String,
        name: String,
        spdx_id: String,
        url: String,
        node_id: String,
      )
    end

    JSON.mapping(
      id: Int64,
      node_id: String,
      name: String,
      full_name: String,
      private: Bool,
      html_url: String,
      description: String,
      fork: Bool,
      url: String,
      created_at: Time,
      updated_at: Time,
      pushed_at: Time,
      git_url: String,
      ssh_url: String,
      clone_url: String,
      svn_url: String,
      homepage: String,
      size: Int64,
      stargazers_count: Int64,
      watchers_count: Int64,
      language: String,
      has_issues: Bool,
      has_projects: Bool,
      has_downloads: Bool,
      has_wiki: Bool,
      has_pages: Bool,
      forks_count: Int64,
      archived: Bool,
      open_issues_count: Int64,
      license: License,
      forks: Int64,
      open_issues: Int64,
      watchers: Int64,
      default_branch: String,
    )
  end

  JSON.mapping(
    zen: String,
    hook_id: Int64,
    hook: Hook,
    repository: Repository,
  )
end

pp GitHubHook.from_json(File.read("hook_added_log.json"))
# CI.build("https://github.com/manveru/bundix", "master")
# Kemal.run
