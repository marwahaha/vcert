GOFLAGS ?= $(GOFLAGS:)
ifdef BUILD_NUMBER
	VERSION=`git describe --abbrev=0 --tags`+$(BUILD_NUMBER)
else
	VERSION=`git describe --abbrev=0 --tags`
endif

GO_LDFLAGS=-ldflags "-X github.com/Venafi/vcert.versionString=$(VERSION) -X github.com/Venafi/vcert.versionBuildTimeStamp=`date -u +%Y%m%d.%H%M%S` -s -w"
version:
	echo "$(VERSION)"

get: gofmt
	go get $(GOFLAGS) ./...

build_quick: get
	env GOOS=linux   GOARCH=amd64 go build $(GO_LDFLAGS) -o bin/linux/vcert         ./cmd/vcert

build: get
	env GOOS=linux   GOARCH=amd64 go build $(GO_LDFLAGS) -o bin/linux/vcert         ./cmd/vcert
	env GOOS=linux   GOARCH=386   go build $(GO_LDFLAGS) -o bin/linux/vcert86       ./cmd/vcert
	env GOOS=darwin  GOARCH=amd64 go build $(GO_LDFLAGS) -o bin/darwin/vcert        ./cmd/vcert
	env GOOS=darwin  GOARCH=386   go build $(GO_LDFLAGS) -o bin/darwin/vcert86      ./cmd/vcert
	env GOOS=windows GOARCH=amd64 go build $(GO_LDFLAGS) -o bin/windows/vcert.exe   ./cmd/vcert
	env  GOOS=windows GOARCH=386   go build $(GO_LDFLAGS) -o bin/windows/vcert86.exe ./cmd/vcert

cucumber:
	rm -rf ./aruba/bin/
	mkdir -p ./aruba/bin/ && cp ./bin/linux/vcert ./aruba/bin/vcert
	docker build --tag vcert.auto aruba/
	if [ -z "$(FEATURE)" ]; then \
		cd aruba && ./cucumber.sh; \
	else \
		cd aruba && ./cucumber.sh $(FEATURE); \
	fi

gofmt:
	! gofmt -l . | grep -v ^vendor/ | grep .

test: get
	go test -v -cover .
	go test -v -cover ./pkg/certificate
	go test -v -cover ./pkg/endpoint
	go test -v -cover ./pkg/venafi/fake
	go test -v -cover ./cmd/vcert/output
	go test -v -cover ./cmd/vcert

tpp_test: get
	go test -v $(GOFLAGS) ./pkg/venafi/tpp     \
		-tpp-url       "${VCERT_TPP_URL}"      \
		-tpp-user      "${VCERT_TPP_USER}"     \
		-tpp-password  "${VCERT_TPP_PASSWORD}" \
		-tpp-zone      "${VCERT_TPP_ZONE}"

cloud_test: get
	go test -v $(GOFLAGS) ./pkg/venafi/cloud   \
		-cloud-url     "${VCERT_CLOUD_URL}"    \
		-cloud-api-key "${VCERT_CLOUD_APIKEY}" \
		-cloud-zone    "${VCERT_CLOUD_ZONE}"

ifdef BUILD_NUMBER
VERSION=`git describe --abbrev=0 --tags`+$(BUILD_NUMBER)
else
VERSION=`git describe --abbrev=0 --tags`
endif

collect_artifacts:
	rm -rf artifcats
	mkdir -p artifcats
	VERSION=`git describe --abbrev=0 --tags`
	mv bin/linux/vcert artifcats/vcert-$(VERSION)_linux
	mv bin/linux/vcert86 artifcats/vcert-$(VERSION)_linux86
	mv bin/darwin/vcert artifcats/vcert-$(VERSION)_darwin
	mv bin/windows/vcert.exe artifcats/vcert-$(VERSION)_windows.exe
	mv bin/windows/vcert86.exe artifcats/vcert-$(VERSION)_windows86.exe
	cd artifcats; sha1sum * > hashsums.sha1

linter:
	golangci-lint run