package check

import (
	"os"
	"os/user"
	"path/filepath"

	"github.com/kudobuilder/kudo/pkg/kudoctl/util/vars"
	"github.com/pkg/errors"
)

const (
	defaultKUDORepoPath   = ".kudo/repo"
	defaultKubeConfigPath = ".kube/config"
)

// ValidateKubeConfigPath checks if the kubeconfig file exists.
func ValidateKubeConfigPath() error {
	path, err := getKubeConfigLocation()
	if err != nil {
		return err
	}

	vars.KubeConfigPath = path
	if _, err := os.Stat(vars.KubeConfigPath); os.IsNotExist(err) {
		return errors.Wrap(err, "failed to find kubeconfig file")
	}
	return nil
}

func getKubeConfigLocation() (string, error) {
	// if vars.KubeConfigPath is not specified, search for the default kubeconfig file under the $HOME/.kube/config.
	if len(vars.KubeConfigPath) == 0 {
		usr, err := user.Current()
		if err != nil {
			return "", errors.Wrap(err, "failed to determine user's home dir")
		}
		return filepath.Join(usr.HomeDir, defaultKubeConfigPath), nil
	}
	return vars.KubeConfigPath, nil
}

// RepoPath checks if the repo path folder exists.
func RepoPath() error {
	// if RepoPath is not specified, search for the default under the $HOME/.kudo/repo.
	if len(vars.RepoPath) == 0 {
		usr, err := user.Current()
		if err != nil {
			return errors.Wrap(err, "failed to determine user's home dir")
		}
		vars.RepoPath = filepath.Join(usr.HomeDir, defaultKUDORepoPath)
	}

	// Option to set a repo path within the environment
	// overrides passed repo path parameter
	repoPathEnv := os.Getenv("KUDO_REPO_PATH")

	if repoPathEnv != "" {
		vars.RepoPath = repoPathEnv
	}

	if _, err := os.Stat(vars.RepoPath); err != nil && os.IsNotExist(err) {
		if err = os.MkdirAll(vars.RepoPath, 0755); err != nil {
			return errors.Wrap(err, "failed to create repo path")
		}
	}
	return nil
}
