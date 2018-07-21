package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"os/exec"
	"runtime"

	macaron "gopkg.in/macaron.v1"

	"github.com/Jeffail/tunny"
	arg "github.com/alexflint/go-arg"
)

var pool *tunny.Pool

var config struct {
	GithubUser  string `arg:"--github-user,required,env:GITHUB_USER"`
	GithubToken string `arg:"--github-token,required,env:GITHUB_TOKEN"`
}

func main() {
	arg.MustParse(&config)

	pool = tunny.NewFunc(runtime.NumCPU(), worker)

	defer pool.Close()

	m := macaron.Classic()
	m.SetAutoHead(true)
	m.Use(macaron.Renderer(macaron.RenderOptions{
		Layout:     "layout",
		Extensions: []string{".html"},
	}))

	setupRouting(m)

	m.Run(8080)
}

func worker(work interface{}) interface{} {
	switch w := work.(type) {
	case *githubJob:
		return w.build()
	}

	return "Couldn't find work type"
}

func runCmd(cmd *exec.Cmd) (*bytes.Buffer, *bytes.Buffer, error) {
	log.Printf("%s %v", cmd.Path, cmd.Args)

	stdoutIn, _ := cmd.StdoutPipe()
	stderrIn, _ := cmd.StderrPipe()

	var stdoutBuf, stderrBuf bytes.Buffer

	if err := cmd.Start(); err != nil {
		return nil, nil, fmt.Errorf("%s failed with %s\n", cmd.Path, err)
	}

	var errStdout, errStderr error

	go func() {
		_, errStdout = io.Copy(&stdoutBuf, stdoutIn)
	}()

	go func() {
		_, errStderr = io.Copy(&stderrBuf, stderrIn)
	}()

	if err := cmd.Wait(); err != nil {
		return &stdoutBuf, &stderrBuf, fmt.Errorf("%s failed with %s\n", cmd.Path, err)
	}

	if errStdout != nil || errStderr != nil {
		return &stdoutBuf, &stderrBuf, fmt.Errorf("failed to capture stdout or stderr\n")
	}

	return &stdoutBuf, &stderrBuf, nil
}
