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

    L.debug res
  end

  def self.set_status(url : URI, status : String, description : String, id : String)
    client = HTTP::Client.new(url)
    client.basic_auth("manveru", ENV["GITHUB_TOKEN"])
    client.post(
      url.path.not_nil!,
      body: {
        "state"       => status,
        "target_url"  => "#{ENV["SERVER_URL"]}/builds/#{id}",
        "description" => description,
        "context":       "Scylla",
      }.to_json
    )
  end
end
