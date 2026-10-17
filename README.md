
> Open this page at [https://ericbusboom.github.io/tigez/](https://ericbusboom.github.io/tigez/)

## Use as Extension

This repository can be added as an **extension** in MakeCode.

* open [https://makecode.microbit.org/](https://makecode.microbit.org/)
* click on **New Project**
* click on **Extensions** under the gearwheel menu
* search for **https://github.com/ericbusboom/tigez** and import

## Edit this project

To edit this repository in MakeCode.

* open [https://makecode.microbit.org/](https://makecode.microbit.org/)
* click on **Import** then click on **Import URL**
* paste **https://github.com/ericbusboom/tigez** and click import

## Local development

Build, flash and edit from this folder instead of the website. You need
[Node.js](https://nodejs.org/) 20+ and the pxt CLI (`npm install -g pxt`).

```sh
make setup      # npm install (micro:bit target) + pxt install (extensions)
make build      # compile to built/binary.hex
make deploy     # build and copy the hex to a plugged-in micro:bit
make code       # open this project in the local MakeCode editor, in Chrome
```

`npm run setup`, `npm run build`, `npm run deploy` and `npm run code` do the
same things.

### The local editor

`make code` runs [scripts/code.sh](scripts/code.sh), which starts `pxt serve`
and opens Google Chrome on this project. Chrome matters: flashing from the
editor's Download button uses WebUSB, which only Chromium browsers have.

Plain `pxt serve` is not enough. It serves the editor from
`node_modules/pxt-microbit`, opens the default browser, and shows an empty
project list, because the editor keeps its own projects in the browser unless
the URL asks for the filesystem workspace. The script links this repo into
`projects/`, writes `.header.json` so the project has a stable id, and opens
`http://localhost:3232/index.html?ws=fs#header:<id>&local_token=...`. Edits in
the editor save straight back to `main.ts` and `main.blocks` here.

pxt always uses ports 3232 and 3233, so a server left running in any other
project blocks this one with `EADDRINUSE`. The script reports the offending
process and how to kill it. To find it by hand:

```sh
lsof -nP -t -iTCP:3233 -sTCP:LISTEN | xargs kill
```

#### Metadata (used for search, rendering)

* for PXT/microbit
<script src="https://makecode.com/gh-pages-embed.js"></script><script>makeCodeRender("{{ site.makecode.home_url }}", "{{ site.github.owner_name }}/{{ site.github.repository_name }}");</script>
