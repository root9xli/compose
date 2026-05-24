/*
Copyright 2020 Docker Compose CLI authors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/docker/compose/v2/cmd/compose/commands"
	"github.com/docker/compose/v2/internal"
	"github.com/spf13/cobra"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle OS signals for graceful shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		select {
		case <-sigCh:
			cancel()
		case <-ctx.Done():
		}
	}()

	if err := run(ctx); err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	cmd := rootCmd()
	return cmd.ExecuteContext(ctx)
}

func rootCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "docker compose",
		Short: "Docker Compose",
		Long: `Define and run multi-container applications with Docker.

Usage:
  docker compose [OPTIONS] COMMAND

Run 'docker compose COMMAND --help' for more information on a command.`,
		Version:          internal.Version,
		SilenceErrors:    true,
		SilenceUsage:     true,
		TraverseChildren: true,
	}

	// Add persistent flags available to all subcommands
	cmd.PersistentFlags().StringP("file", "f", "", "Compose configuration files")
	cmd.PersistentFlags().String("project-name", "", "Project name")
	cmd.PersistentFlags().String("profile", "", "Specify a profile to enable")
	cmd.PersistentFlags().Bool("dry-run", false, "Execute command in dry run mode")
	cmd.PersistentFlags().Bool("ansi", true, "Control when to print ANSI control characters")
	cmd.PersistentFlags().Bool("no-ansi", false, "Do not print ANSI control characters (DEPRECATED)")
	_ = cmd.PersistentFlags().MarkHidden("no-ansi")

	// Register subcommands
	commands.AddCommands(cmd)

	return cmd
}
