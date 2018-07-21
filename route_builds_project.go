package main

import (
	"path/filepath"
	"strings"

	macaron "gopkg.in/macaron.v1"
)

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

type projectBuild struct {
	Project, ID string
}
