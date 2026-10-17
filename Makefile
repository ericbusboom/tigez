PORT ?= 3232
export PORT

.PHONY: all setup build deploy test code clean help

all: deploy

## setup — install the micro:bit target (npm) and the project's extensions (pxt)
setup:
	npm install --no-audit --no-fund
	pxt install

## build — compile to built/binary.hex
build:
	pxt build

## deploy — build and copy the hex to a plugged-in micro:bit
deploy:
	pxt deploy

## test — run test.ts
test:
	pxt test

## code — open this project in the local MakeCode editor, in Chrome (make code PORT=8080)
code:
	bash scripts/code.sh

## clean — remove build output and installed extensions
clean:
	rm -rf built pxt_modules projects .header.json .simstate.json

## help — list targets
help:
	@grep -E '^## ' Makefile | sed 's/## //'
