generate-js: deps
	@find src -name '*.coffee' | xargs coffee -c -o lib

remove-js:
	@rm -fr lib/

deps:
	@test `which coffee` || echo 'You need to have CoffeeScript in your PATH.\nPlease install it using `brew install coffee-script` or `npm install coffee-script`.'

publish: generate-js has-npm
	npm publish
	@$(MAKE) remove-js

link: generate-js has-npm
	npm link
	@$(MAKE) remove-js

dev: generate-js
	@coffee -wc --no-wrap -o lib src/*.coffee

has-npm:
	@test `which npm` || echo 'You need npm installed for this command'

install: generate-js

clean: remove-js

.PHONY: generate-js remove-js deps publish link dev has-npm install clean
