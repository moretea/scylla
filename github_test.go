package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGithubJob(t *testing.T) {
	job := &githubJob{hook: &GithubHook{}}
	job.hook.Repository.FullName = "manveru/scylla"
	job.hook.PullRequest.Head.Sha = "sample"

	Convey("pname creation", t, func() {
		So(job.pname(), ShouldEqual, "manveru_scylla-sample")
	})

	Convey("sourceDir", t, func() {
		So(job.sourceDir(), ShouldEqual, "ci/manveru_scylla/sample/source")
	})

	Convey("resultLink", t, func() {
		So(job.resultLink(), ShouldEqual, "ci/manveru_scylla/sample/result")
	})
}
