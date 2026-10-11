REPO ?= m-this/tf2-config
VERSION ?= dev
BUILD_CHANNEL ?= release
ZIP_URL ?= https://github.com/$(REPO)/releases/latest/download/budhud.zip

SERVE_ADDRESS ?= 192.168.50.133
SERVE_PORT ?= 80
NGINX_IMAGE ?= nginx:1.30.5-alpine

.PHONY: dist serve unserve clean

dist:
	VERSION=$(VERSION) BUILD_CHANNEL=$(BUILD_CHANNEL) ZIP_URL=$(ZIP_URL) ./build.sh

serve:
	$(MAKE) dist ZIP_URL=http://$(SERVE_ADDRESS)$(if $(filter 80,$(SERVE_PORT)),,:$(SERVE_PORT))/budhud.zip
	rm -rf serve && cp -R dist serve
	docker rm -f tf2-config-serve >/dev/null 2>&1 || true
	docker run -d --name tf2-config-serve --restart unless-stopped \
		-p $(SERVE_ADDRESS):$(SERVE_PORT):80 \
		-v $(CURDIR)/serve:/usr/share/nginx/html:ro $(NGINX_IMAGE)
	@echo http://$(SERVE_ADDRESS)$(if $(filter 80,$(SERVE_PORT)),,:$(SERVE_PORT))/budhud.bat

unserve:
	docker rm -f tf2-config-serve

clean:
	rm -rf build dist serve
