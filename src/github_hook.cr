# body = File.read("/mnt/big/github/manveru/scylla/hook_pr_synchronize.json")
# GitHubHook::PullRequest.from_json(body).handle(body)

struct GitHubHook
  JSON.mapping(
    zen: String,
    hook_id: Int64,
    hook: Hook,
    repository: Repository,
  )

  def self.handle(body, event)
    L.debug body

    case event
    when "pull_request"
      spawn do
        GitHubHook::PullRequest.from_json(body).handle(body)
      end
    end
  end

  struct PullRequest
    JSON.mapping(
      action: String,
      number: Int64,
      pull_request: PR,
    )

    def handle(hook_data : String)
      project_id = create_project
      uuid = create_result(hook_data, project_id)

      status "pending", "Evaluating", uuid

      result = CI.build_from_git(
        pull_request.head.repo.clone_url,
        pull_request.head.sha,
        uuid,
      )

      status = result.exit_status
      update_exit_status(uuid, status)

      if result.success?
        status "success", "Evaluation succeeded", uuid
      else
        status "failure", "something went wrong", uuid
      end
    rescue ex
      L.error ex
      status "error", ex.to_s[0..138], (uuid || "")
    end

    def update_exit_status(uuid, status)
      Repo.exec(<<-SQL, status, Time.now, uuid)
        UPDATE results SET exit_status = $1, finished_at = $2 WHERE id = $3
      SQL
    end

    private def create_project
      head = pull_request.head
      Repo.query_one(<<-SQL, "github", head.repo.name, head.user.login, head.repo.html_url, as: {String})
        INSERT INTO projects (kind, name, owner, link) VALUES ($1, $2, $3, $4)
        ON CONFLICT (link) DO UPDATE SET id = projects.id
        RETURNING projects.id
      SQL
    end

    private def status(kind : String, desc : String, id : String)
      @uri ||= URI.parse(pull_request.statuses_url)
      GitHubClient.set_status(@uri.not_nil!, kind, desc, id)
    end

    private def create_result(hook_data : String, project_id : String)
      uuid = Repo.query_one(<<-SQL, hook_data, Time.now, project_id, as: {String})
        INSERT INTO results (hook_data, created_at, project_id)
        VALUES ($1, $2, $3)
        RETURNING id
      SQL
    end

    struct PR
      struct Head
        JSON.mapping(
          label: String,
          ref: String,
          sha: String,
          repo: Repository,
          user: User,
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

    struct LastResponse
      JSON.mapping(
        code: (Int64 | Nil),
        status: String,
        message: String | Nil,
      )
    end
  end

  struct User
    JSON.mapping(
      login: String,
    )
  end

  struct License
    JSON.mapping(
      key: String,
      name: String,
      spdx_id: String,
      url: String,
      node_id: String,
    )
  end

  struct Repository
    JSON.mapping(
      id: Int64,
      node_id: String,
      name: String,
      full_name: String,
      private: Bool,
      html_url: String,
      description: String,
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
      archived: Bool,
      forks: Int64,
      open_issues: Int64,
      watchers: Int64,
      default_branch: String,
    )
  end
end
