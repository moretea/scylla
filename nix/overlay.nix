with builtins;

self: super: {
  go = super.go_1_11;
  decrypt-ejson = path:
    (fromJSON (readFile
      (super.runCommand "ejson" { nativeBuildInputs = with super; [ ruby ejson jq ]; } ''
        export EJSON_KEYDIR='${/opt/ejson/keys}'
        ejson decrypt '${path}' | ruby ${./ejson.rb} > $out
      '')));
  makeDeploymentID = sha:
    super.lib.removeSuffix "\n" (readFile (
      super.runCommand "deployment_id" {sha = sha;} ''
        ${super.ruby}/bin/ruby -r securerandom -e 'print ENV["sha"][0...8] + "-#{SecureRandom.hex(4)}"' > $out
      ''
    ));
  tagFromGit = self.git-info "git rev-parse --verify HEAD";
  dbmate = self.callPackage ./pkgs/dbmate {};
  mkShell = super.mkShell.override { stdenv = self.stdenvNoCC; };
  nodejs = super.nodejs-slim-10_x;
  git-info = cmd: repo:
    super.lib.removeSuffix "\n" (readFile (
      super.stdenv.mkDerivation rec {
        name = "git-info";
        src = super.lib.sourceByRegex repo ["\.git.*"];
        passAsFile = ["buildCommand"];
        buildInputs = [super.git];
        buildCommand = ''
          cd $src
          ${cmd} > $out
        '';
  }));
}
