package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	macaron "gopkg.in/macaron.v1"
)

func getBuildsProjectId(ctx *macaron.Context) {
	projectName := ctx.Params("project")
	buildID := ctx.Params("id")
	idPath := filepath.Join("ci", projectName, buildID)
	hookJSON := filepath.Join(idPath, "hook.json")
	job := newGithubJobFromJSONFile(hookJSON)
	if job == nil {
		ctx.Error(404, "Couldn't find Build", projectName, buildID)
		return
	}

	infos, err := buildIDInfos(idPath)
	if err == nil {
		ctx.Data["Results"] = infos
	} else {
		ctx.Error(500, err.Error())
		return
	}

	if len(infos) == 0 { // apparently the build failed, let's ask nix log
		sout, serr, err := job.nixLog()
		ctx.Data["NixLogStdout"] = sout
		ctx.Data["NixLogStderr"] = serr
		ctx.Data["NixLogErr"] = err
	}

	ctx.Data["ProjectLink"] = "/builds/" + projectName
	ctx.Data["Job"] = job
	ctx.HTML(200, "builds_project_id")
}

type projectIDResult struct {
	NixPath              string
	NixStdout, NixStderr string
	NixError             error
}

func nixLog(nixPath string) (string, string, error) {
	stdoutBuf, stderrBuf, err := runCmd(exec.Command("nix", "log", nixPath))
	if err != nil {
		return "", "", err
	}
	return stdoutBuf.String(), stderrBuf.String(), nil
}

func buildIDInfos(idPath string) (map[string]projectIDResult, error) {
	resultLinks, _ := filepath.Glob(filepath.Join(idPath, "result*"))
	infos := map[string]projectIDResult{}
	for _, resultLink := range resultLinks {
		resolved, err := os.Readlink(resultLink)
		if err != nil {
			return nil, fmt.Errorf("Failed resolving result link %s: %s\n", resultLink, err)
		}
		no, ne, err := nixLog(resolved)
		infos[resolved] = projectIDResult{
			NixPath:   resolved,
			NixStdout: no,
			NixStderr: ne,
			NixError:  err,
		}
	}
	return infos, nil
}
