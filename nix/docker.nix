{ callPackage, dockerTools, git-info, bashInteractive }:
let
  Labels = {
    maintainer = "Michael Fellinger <mf@seitenschmied.at>";
    "com.xing.docker_build.target" = "misc";
    "com.xing.git.sha1"   = git-info "git rev-parse --verify HEAD" ./..;
    "com.xing.git.time"   = git-info "git show -s --format=%cI HEAD" ./..;
    "com.xing.git.remote" = git-info "git config --get remote.origin.url" ./..;
  };
  scylla = callPackage ./.. {};
in
dockerTools.buildImage {
  name = "scylla";
  tag = "misc";
  created = Labels."com.xing.git.time";
  config = {
    inherit Labels;
    WorkingDir = "/";
    EntryPoint = ["${bashInteractive}/bin/bash"];
    Env = [
      "HOST=0.0.0.0"
      "PORT=80"
    ];
    ExposedPorts = {
      "80/tcp" = {};
    };
  };
  contents = [ scylla ];
}
