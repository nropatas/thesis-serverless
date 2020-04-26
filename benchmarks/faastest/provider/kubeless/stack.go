package kubeless

import (
	"path/filepath"

	"github.com/nuweba/faasbenchmark/stack"
	"github.com/nuweba/faasbenchmark/stack/sls"
)

type Stack struct {
	*sls.Stack
}

func (kubeless *Kubeless) NewStack(stackPath string) (stack.Stack, error) {
	stackPath = filepath.Join(stackPath, kubeless.Name())
	stack, err := sls.New(kubeless.Name(), stackPath)

	if err != nil {
		return nil, err
	}

	return &Stack{stack}, nil
}
