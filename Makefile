IMAGE = multiarch/crossbuild:dev
LINUX_TRIPLES = arm-linux-gnueabi powerpc64le-linux-gnu aarch64-linux-gnu arm-linux-gnueabihf mipsel-linux-gnu
DARWIN_TRIPLES = x86_64-apple-darwin i386-apple-darwin
# FIXME: handle x86_64h-apple-darwin14
DOCKER_TEST_ARGS ?= -it --rm -v $(shell pwd)/test:/test -w /test


all: build


.PHONY: build
build: .built


.built: Dockerfile $(shell find ./assets/)
	docker build -t $(IMAGE) .
	docker inspect -f '{{.Id}}' $(IMAGE) > $@


.PHONY: shell
shell: .built
	docker run $(DOCKER_TEST_ARGS) $(IMAGE)


.PHONY: test
test: .built
	# generic test
	for triple in "" $(DARWIN_TRIPLES) $(LINUX_TRIPLES); do                         \
	  docker run $(DOCKER_TEST_ARGS) -e CROSS_TRIPLE=$$triple $(IMAGE) make test;   \
	done
	# osxcross wrapper testing
	docker run $(DOCKER_TEST_ARGS) -e CROSS_TRIPLE=i386-apple-darwin14 $(IMAGE) /usr/osxcross/bin/i386-apple-darwin14-cc helloworld.c -o helloworld
	file test/helloworld
	docker run $(DOCKER_TEST_ARGS) -e CROSS_TRIPLE=i386-apple-darwin14 $(IMAGE) /usr/i386-apple-darwin14/bin/cc helloworld.c -o helloworld
	file test/helloworld
	docker run $(DOCKER_TEST_ARGS) -e CROSS_TRIPLE=i386-apple-darwin14 $(IMAGE) cc helloworld.c -o helloworld
	file test/helloworld


.PHONY: clean
clean:
	@rm -f .built
	@for cid in `docker ps | grep crossbuild | awk '{print $$1}'`; do docker kill $$cid; done || true


.PHONY: re
re: clean all
