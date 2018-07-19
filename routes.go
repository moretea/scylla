package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"

	"github.com/go-macaron/binding"
	macaron "gopkg.in/macaron.v1"
)

func setupRouting(m *macaron.Macaron) {
	m.Get("/", getIndex)
	m.Get("/builds", getBuilds)
	m.Get("/builds/:project", getBuildsProject)
	m.Get("/builds/:project/:id", getBuildsProjectId)
	m.Get("/projects", getProjects)
	m.Post("/hooks/github", binding.Bind(GithubHook{}), postHooksGithub)
}

func getIndex(ctx *macaron.Context) {
	ctx.HTML(200, "index")
}

type projectBuild struct {
	Project, ID string
}

func getBuildsProject(ctx *macaron.Context) {
	projectName := ctx.Params("project")
	projectPath := filepath.Join("ci", projectName)
	projectIDs, _ := filepath.Glob(filepath.Join(projectPath, "*"))
	projectBuilds := make([]projectBuild, len(projectIDs))
	for i, projectID := range projectIDs {
		parts := strings.Split(projectID, "/")
		projectBuilds[i] = projectBuild{
			Project: parts[1],
			ID:      parts[2],
		}
	}

	ctx.Data["Name"] = projectPretty(projectName)
	ctx.Data["Builds"] = projectBuilds
	ctx.HTML(200, "builds_project")
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

	if infos, err := buildIDInfos(idPath); err == nil {
		ctx.Data["Results"] = infos
	} else {
		ctx.Error(500, err.Error())
	}

	ctx.Data["Job"] = job
	ctx.HTML(200, "builds_project_id")
}

type projectInfo struct {
	Name, Link string
	BuildCount int
}

func projectPretty(name string) string {
	return strings.Replace(filepath.Base(name), "_", "/", 1)
}

func getProjects(ctx *macaron.Context) {
	projectNames, _ := filepath.Glob("ci/*")
	projectInfos := make([]projectInfo, len(projectNames))

	for i, name := range projectNames {
		projectName := projectPretty(name)
		buildCount := subdirCount(name)
		projectInfos[i] = projectInfo{
			Link:       filepath.Base(name),
			Name:       projectName,
			BuildCount: buildCount,
		}
	}

	ctx.Data["Projects"] = projectInfos
	ctx.HTML(200, "projects")
}

func subdirCount(name string) int {
	info, err := os.Stat(name)
	if err != nil {
		log.Printf("Failed to stat %s: %s\n", name, err)
		return 0
	}

	rvalue := reflect.ValueOf(info.Sys())
	nlink := rvalue.Elem().FieldByName("Nlink")
	if !nlink.IsValid() { // use the wasteful path
		count, _ := filepath.Glob(filepath.Join(name, "/*/"))
		return len(count)
	}
	return int(nlink.Uint() - 2)
}

type meta struct {
	Path string
	Rev  string `json:"rev"`
	URL  string `json:"url"`
}

func getBuilds(ctx *macaron.Context) {
	metas := []meta{}

	filepath.Walk("ci", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			log.Println(err)
			return err
		}

		if filepath.Base(path) == "result" {
			resolved, err := filepath.EvalSymlinks(path + "/meta.json")
			if err != nil {
				log.Println(err)
			}
			content, err := ioutil.ReadFile(resolved)
			if err != nil {
				log.Println(err)
			}
			m := meta{Path: path}
			json.NewDecoder(bytes.NewBuffer(content)).Decode(&m)
			metas = append(metas, m)
		}
		return nil
	})

	ctx.Data["metas"] = metas
	ctx.HTML(200, "builds")
}
