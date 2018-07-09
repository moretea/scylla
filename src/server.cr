require "kemal"
require "file_utils"
require "json"
require "http/client"

module Util
  struct ShResult
    property stdout : Array(String), stderr : Array(String), status : Process::Status

    def initialize(@stdout, @stderr, @status)
    end
  end

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

    ShResult.new(stdout, stderr, $?)
  end
end

struct GitHubClient
  def self.prs(owner : String, name : String)
    res = HTTP::Client.post(
      "https://api.github.com/graphql",
      headers: HTTP::Headers{
        "Authorization" => "bearer #{ENV["GITHUB_TOKEN"]}",
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

  def self.set_status(url : URI, status : String)
    client = HTTP::Client.new(url)
    client.basic_auth("manveru", ENV["GITHUB_TOKEN"])
    res = client.post(
      url.path.not_nil!,
      body: {
        "state"       => status,
        "target_url"  => "http://example.com",
        "description" => "Building...",
        "context":       "Scylla",
      }.to_json
    )
    pp res
  end
end

struct CI
  extend Util

  def self.build_from_git(clone_url : String, sha : String)
    dest = "ci/#{clone_url.gsub(/\W+/, "_")}-#{sha}"
    FileUtils.mkdir_p dest
    pp sh("git", "clone", clone_url, "#{dest}/clone")
    status = sh("nix-build", "--no-out-link", "--show-trace", "./#{dest}/clone/ci.nix")
  rescue ex
    raise ex
  ensure
    if status
      File.write("#{dest}/stdout", status.stdout.join("\n"))
      File.write("#{dest}/stderr", status.stderr.join("\n"))
    end
  end
end

get "/" do
  # render "src/views/index.ecr"
end

post "/github-webhook" do |env|
  pp env
  if body_io = env.request.body
    GitHubHook.handle(body_io.gets_to_end, env.request.headers["X-GitHub-Event"])
    "OK"
  end
end

struct GitHubHook
  TYPE_MAPPING = {
    "pull_request" => GitHubHook::PullRequest,
  }

  def self.handle(body, event)
    puts body
    if handler = TYPE_MAPPING[event]?
      handler.from_json(body).handle
    else
      puts body
    end
  end

  struct PullRequest
    JSON.mapping(
      action: String,
      number: Int64,
      pull_request: PR,
    )

    def handle
      status "pending"
      pp CI.build_from_git(pull_request.head.repo.clone_url, pull_request.head.sha)
      status "success"
    rescue ex
      pp ex
      status "failure"
    end

    def status(kind)
      @uri ||= URI.parse(pull_request.statuses_url)
      GitHubClient.set_status(@uri.not_nil!, kind)
    end

    struct PR
      struct Head
        JSON.mapping(
          label: String,
          ref: String,
          sha: String,
          repo: Repository,
        )
      end

      JSON.mapping(
        url: String,
        id: Int64,
        node_id: String,
        html_url: String,
        diff_url: String,
        patch_url: String,
        issue_url: String,
        number: Int64,
        state: String,
        locked: Bool,
        title: String,
        commits_url: String,
        review_comments_url: String,
        review_comment_url: String,
        comments_url: String,
        statuses_url: String,
        body: String,
        created_at: Time,
        updated_at: Time,
        closed_at: Time | Nil,
        merged_at: Time | Nil,
        merge_commit_sha: String | Nil,
        head: Head,
      )
    end
  end

  struct Push
    JSON.mapping(
      ref: String,
      after: String,
      repository: Repository
    )
  end

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
      statuses_url: String,
      git_url: String,
      ssh_url: String,
      clone_url: String,
      svn_url: String,
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

# CI.build("https://github.com/manveru/bundix", "master")
Kemal.run
