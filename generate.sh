#!/bin/sh
if [ $# != 1 ]; then
	echo >&2 "usage: $(basename "$0") <filename.wav>"
	exit 1
fi

filename="$1"
name="$(basename -s .wav "${filename}")"
root="$(dirname "$0")"

mkdir -p "${root}/cmd/${name}"
cp "${filename}" "${root}/cmd/${name}/${name}.wav"
gofmt > "${root}/cmd/${name}/${name}.go" << EOF
package main

import (
	"io/ioutil"
	"os"
	"os/exec"
)

//go:generate ../../generate.sh ${name}.wav
func main() {
	f, err := ioutil.TempFile(os.TempDir(), "${name}")
	if err != nil {
		panic(err)
	}
	defer os.Remove(f.Name())
	if _, err := f.Write(${name}); err != nil {
		panic(err)
	}
	cmd := exec.Command("afplay", f.Name())
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		panic(err)
	}
}

var ${name} = []byte{
	$(xxd -i < "${filename}" | sed 's/\([^,]\)$/\1,/')
}
EOF