package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGithubJob(t *testing.T) {
	job := &githubJob{Hook: &GithubHook{}}
	job.Hook.Repository.FullName = "manveru/scylla"
	job.Hook.PullRequest.Head.Sha = "sample"
	job.Host = "http://example.com"

	Convey("pname creation", t, func() {
		So(job.pname(), ShouldEqual, "manveru_scylla-sample")
	})

	Convey("sourceDir", t, func() {
		So(job.sourceDir(), ShouldEqual, "ci/manveru_scylla/sample/source")
	})

	Convey("resultLink", t, func() {
		So(job.resultLink(), ShouldEqual, "ci/manveru_scylla/sample/result")
	})

	Convey("progressURL", t, func() {
		So(job.targetURL(), ShouldEqual, "http://example.com/builds/manveru_scylla/sample")
	})
}

func TestGithubNixLogFallback(t *testing.T) {
	input := []byte(`
builder for '/nix/store/frazyff503b84jiwhdqzbr5m853x6f3p-scylla-unstable-2018-07-21.drv' failed with exit code 2; last 10 log lines:
  unpacking source archive /nix/store/mc4iy0zchn3svak19ng0s89wyyr3jv95-cli-8e01ec4
  unpacking source archive /nix/store/xbrim0lafs0jx2kyyca63xb05ww17dxs-crypto-a214413
  unpacking source archive /nix/store/a831738dpawiv4rmn0sjz4v0vbnpwsia-sys-ac767d6
  unpacking source archive /nix/store/vbnymrfr5g45x5015xia93rf7cf5lhxy-fsnotify-c282820
  unpacking source archive /nix/store/v0k4bhi2hynpsxqxq7k3s1prh0lmg469-ini-358ee76
  unpacking source archive /nix/store/xivs375qda26zdhg0gjiq0xk6dqcqkmk-macaron-88a29ec
  building
  # github.com/manveru/scylla
  go/src/github.com/manveru/scylla/github.go:216:2: undefined: fail
  FAIL  github.com/manveru/scylla [build failed]
error: build of '/nix/store/a77gsrrrbcrs2karrip3313j8id6q2xw-docker-image-scylla.tar.gz.drv', '/nix/store/frazyff503b84jiwhdqzbr5m853x6f3p-scylla-unstable-2018-07-21.drv' failed
`)
	Convey("Parse failing .drv from log", t, func() {
		drvs := parseDrvsFromStderr(input)
		So(drvs, ShouldResemble, []string{
			"/nix/store/a77gsrrrbcrs2karrip3313j8id6q2xw-docker-image-scylla.tar.gz.drv",
			"/nix/store/frazyff503b84jiwhdqzbr5m853x6f3p-scylla-unstable-2018-07-21.drv",
		})
	})
}
