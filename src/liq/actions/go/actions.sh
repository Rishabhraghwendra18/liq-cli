go-get-deps() {
  colorerr "GOPATH=${GOPATH} bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; go get ./...'"
}

go-build() {
  colorerr "GOPATH=${GOPATH} bash -c 'go build $REL_GOAPP_PATH'"
}

go-test() {
  colorerr "GOPATH=${GOPATH} bash -c 'go test $REL_GOAPP_PATH'"
}
