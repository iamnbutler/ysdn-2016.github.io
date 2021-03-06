
#
# Binaries
#

BIN := ./node_modules/.bin

#
# Variables
#

PORT      ?= 8080
HOST      ?= localhost
NODE_ENV  ?= development

LAYOUTS    = $(shell find ./layouts -type f -name '*.html')
CONTENT    = $(shell find ./content -type f -name '*.md' -or -type f -name '*.yml')
MIXINS     = $(shell find ./lib -type f -name '*.js')

IMAGES     = $(shell find ./assets -type f -name '*.jpg' -or -type f -name '*.png' -or -type f -name '*.gif' -or -type f -name '*.svg')
STYLES     = $(shell find ./assets -type f -name '*.scss')
SCRIPTS    = $(shell find ./assets -type f -name '*.js' -not -path "*vendor*")
LIBRARIES  = $(shell find ./assets/js/vendor -type f -name '*.js' -not -path "*jquery.js")

ICONS      = $(shell find './assets/icons/' -type f -name '*.svg')

BROWSERIFY_ARGS = -t partialify

DOMAIN     = ysdn2016.com
STAGING    = staging.ysdn2016.com
REPO       = ysdn-2016/ysdn-2016.github.io
BRANCH     = $(shell git rev-parse --abbrev-ref HEAD)

API        = https://api.ysdn2016.com

#
# Tasks
#

build: node_modules content assets styles scripts
start: build
	@bin/www

watch: install build
	@$(BIN)/onchange 'content/**/*.{md,yml}' 'layouts/**/*.html' 'lib/**/*.js' -- make content & \
		$(BIN)/onchange 'assets/css/**/*.scss' -- make styles & \
		$(BIN)/onchange 'assets/{fonts,images}/**/*' -- make assets & \
		$(BIN)/onchange 'assets/js/vendor/**/*.js' -- make build/assets/libraries.js & \
		$(BIN)/watchify $(BROWSERIFY_ARGS) assets/js/index.js -o build/assets/bundle.js & \
		$(BIN)/wtch --dir build 2>&1 >/dev/null & \
		bin/www & wait

sync: clean-content
	@mkdir -p content/students
	@curl -s "$(API)/download" | tar -zxf - -C content/students --strip-components=1

sync-portraits:
	@node resources/add-profile-images/index.js

sync-weight:
	@(cd resources/assign-project-weight/ && node index.js)

deploy:
	@echo "Building site for \033[0;33mstaging\033[0m..."
	@make clean
	@make clean-content
	@make sync
	@NODE_ENV=production make build
	@echo "Deploying branch \033[0;33m$(BRANCH)\033[0m to Github Pages (staging)..."
	@(cd build && \
		printf 'User-agent: *\nDisallow: /\n' > robots.txt && \
		echo "$(STAGING)" > CNAME && \
		git init -q . && \
		git add . && \
		git commit -q -m "Deployment (auto-commit)" && \
		echo "\033[0;90m" && \
		git push "git@github.com:ysdn-2016/staging.git" HEAD:gh-pages --force && \
		echo "\033[0m")
	@echo "Deployed to \033[0;32mhttp://$(STAGING)/\033[0m"

deploy\:production:
	@if [[ "$(BRANCH)" != "production" ]]; then sleep 0.5 && echo "\n\033[0;31mERROR:\033[0m Deployments can only happen in the \033[0;33mproduction\033[0m branch\nMerge your changes into \033[0;33mproduction\033[0m and try again.\n" && tput bel && exit 1; fi
	@echo "Building site for \033[0;33mstaging\033[0m..."
	@make clean
	@make sync
	@NODE_ENV=production make build
	@echo "Deploying branch \033[0;33mproduction\033[0m to Github pages..."
	@(cd build && \
		echo "$(DOMAIN)" > CNAME && \
		git init -q . && \
		git add . && \
		git commit -q -m "Deployment (auto-commit)" && \
		echo "\033[0;90m" && \
		git push "git@github.com:$(REPO).git" HEAD:master --force && \
		echo "\033[0m")
	@make clean
	@echo "Deployed to \033[0;32mhttp://$(DOMAIN)\033[0m"

fmt: comb semistandard

semistandard:
	@$(BIN)/semistandard-format -w $(SCRIPTS)

comb:
	@csscomb assets/css -v

test:
	@true

clean:
	@rm -rf build
clean-content:
	@rm -rf content/students
clean-deps:
	@rm -rf node_modules

#
# Shorthands
#

install: node_modules
content: build/index.html
assets:  build/assets/fonts build/assets/images build/favicon.png
styles:  build/assets/bundle.css
scripts: build/assets/bundle.js build/assets/libraries.js
icons:   assets/fonts/icons

#
# Targets
#

node_modules: package.json
	@npm install

build/index.html: bin/build $(CONTENT) $(LAYOUTS) $(MIXINS)
	@bin/build

build/favicon.png: assets/images/favicon.png
	@mkdir -p $(@D)
	@cp -r $< $@

build/assets/%: assets/%
	@mkdir -p $(@D)
	@cp -r $< $@

build/assets/bundle.css: $(STYLES)
	@mkdir -p $(@D)
	@sassc -m assets/css/index.scss $@
	@$(BIN)/postcss --use autoprefixer $@ -o $@

build/assets/bundle.js: $(SCRIPTS)
	@mkdir -p $(@D)
	@$(BIN)/browserify $(BROWSERIFY_ARGS) assets/js/index.js -o $@

build/assets/libraries.js: $(LIBRARIES)
	@cat assets/js/vendor/jquery.js $^ > $@

assets/fonts/icons: assets/icons/icons.sketch assets/icons/config.yml $(ICONS)
	@fontcustom compile -c assets/icons/config.yml

#
# Phony
#

.PHONY: develop clean clean-deps
