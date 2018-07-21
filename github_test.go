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
