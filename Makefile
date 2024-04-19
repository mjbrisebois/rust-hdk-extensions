
.PHONY:			FORCE
SHELL			= bash
TARGET			= release
TARGET_DIR		= target/wasm32-unknown-unknown/release
SOURCE_FILES		= Makefile Cargo.* src/*.rs src/*/*



#
# Project
#
tests/package-lock.json:	tests/package.json
	touch $@
tests/node_modules:		tests/package-lock.json
	cd tests; \
	npm install
	touch $@
clean:
	rm -rf \
	    tests/node_modules \
	    .cargo \
	    target

use-local-backdrop:
	cd tests; npm uninstall @whi/holochain-backdrop
	cd tests; npm install --save-dev ../../node-holochain-backdrop/
use-npm-backdrop:
	cd tests; npm uninstall @whi/holochain-backdrop
	cd tests; npm install --save-dev @whi/holochain-backdrop

use-local-into-struct:
	cd tests; npm uninstall @whi/into-struct
	cd tests; npm install --save-dev ../../projects/js-into-struct/
use-npm-into-struct:
	cd tests; npm uninstall @whi/into-struct
	cd tests; npm install --save-dev @whi/into-struct



#
# Packages
#
preview-crate:			test
	cargo publish --dry-run --allow-dirty
publish-crate:			test .cargo/credentials
	make docs
	cargo publish
.cargo/credentials:
	cp ~/$@ $@



#
# Testing
#
DEBUG_LEVEL	       ?= warn
TEST_ENV_VARS		= LOG_LEVEL=$(DEBUG_LEVEL)
MOCHA_OPTS		= -n enable-source-maps

reset:
	rm -f tests/*.dna
	rm -f tests/zomes/*.wasm
tests/%.dna:			FORCE
	cd tests; make $*.dna
test-setup:			tests/node_modules

test:
	make -s test-unit
	make -s test-integration

test-unit:
	RUST_BACKTRACE=1 cargo test -- --nocapture

MODEL_DNA			= tests/model_dna.dna

test-integration:		test-setup $(MODEL_DNA)
	cd tests; $(TEST_ENV_VARS) npx mocha $(MOCHA_OPTS) integration/test_basic.js



#
# Repository
#
clean-remove-chaff:
	@find . -name '*~' -exec rm {} \;
clean-files:		clean-remove-chaff
	git clean -nd
clean-files-force:	clean-remove-chaff
	git clean -fd
clean-files-all:	clean-remove-chaff
	git clean -ndx
clean-files-all-force:	clean-remove-chaff
	git clean -fdx

PRE_HDI_VERSION = "0.4.0-beta-dev.30"
NEW_HDI_VERSION = "0.4.0-beta-dev.34"

PRE_HDK_VERSION = "0.3.0-beta-dev.34"
NEW_HDK_VERSION = "0.3.0-beta-dev.38"

GG_REPLACE_LOCATIONS = ':(exclude)*.lock' tests/*_types Cargo.toml

update-hdk-version:
	git grep -l $(PRE_HDK_VERSION) -- $(GG_REPLACE_LOCATIONS) | xargs sed -i 's/$(PRE_HDK_VERSION)/$(NEW_HDK_VERSION)/g'
update-hdi-version:
	git grep -l $(PRE_HDI_VERSION) -- $(GG_REPLACE_LOCATIONS) | xargs sed -i 's/$(PRE_HDI_VERSION)/$(NEW_HDI_VERSION)/g'



#
# Documentation
#
MAIN_DOCS		= target/doc/hdk_extensions/index.html
test-docs:
	cargo test --doc
$(MAIN_DOCS):		test-docs
	cargo doc
	@echo -e "\x1b[37mOpen docs in file://$(shell pwd)/$(MAIN_DOCS)\x1b[0m";
docs:			$(MAIN_DOCS)
docs-watch:
	@inotifywait -r -m -e modify		\
		--includei '.*\.rs'		\
			src/			\
	| while read -r dir event file; do	\
		echo -e "\x1b[37m$$event $$dir$$file\x1b[0m";\
		make docs;			\
	done
