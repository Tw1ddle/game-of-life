[![Project logo](https://github.com/Tw1ddle/game-of-life/blob/master/screenshots/logo.png?raw=true "Game Of Life WebGL logo")](http://www.samcodes.co.uk/project/game-of-life/)

Interactive implementation of **Conway's Game of Life** written in Haxe and three.js. Try it now [in your browser](http://www.samcodes.co.uk/project/game-of-life/).

## Features
* Interact with thousands of Game of Life patterns, or create your own in realtime.
* Speed up, slow down, step, pause and clear the simulation.
* Create and share snapshots of the simulation state.
* Custom visuals, including showing dead cells.
* Zoom and pan the universe.

## Usage

Try the [demo](http://www.samcodes.co.uk/project/game-of-life/) and simulate Life. Here it is in action:

[![Screenshot](https://github.com/Tw1ddle/game-of-life/blob/master/screenshots/screenshot1.png?raw=true "Game Of Life WebGLscreenshot 1")](http://www.samcodes.co.uk/project/game-of-life/)

[![Screenshot](https://github.com/Tw1ddle/game-of-life/blob/master/screenshots/screenshot2.png?raw=true "Game Of Life WebGL screenshot 2")](http://www.samcodes.co.uk/project/game-of-life/)

## How It Works
The Game of Life is a cellular automaton invented by John Conway in 1970. The simulation takes place on a two-dimensional orthogonal grid of square cells, each of which can either be dead or alive.

Each time the simulation is updated, every cell interacts with its eight neighboring cells according to these four rules:

* Any live cell with fewer than two living neighbours dies (isolation).
* Any cell with two or three living neighbours survives until the next generation (survival).
* Any cell with more than three living neighbours dies (overpopulation).
* Any dead cell with three living neighbours comes to life (reproduction).

Conway designed these rules carefully to produce interesting results. Read more [here](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life).

## Notes
* Inspired by [Golly](https://sourceforge.net/projects/golly/), a cross-platform simulator for the Game of Life and other cellular automata.
* The Game of Life was invented by [John Conway](https://en.wikipedia.org/wiki/John_Horton_Conway) in 1970.
* If you have any questions or suggestions then [get in touch](http://samcodes.co.uk/contact) or open an issue.

## License
* The pattern files included and embedded in this repository come from the [LifeWiki](http://www.conwaylife.com/wiki/Main_Page) pattern collection, and are by various authors.
* The Haxe code and webpage code in this repository, but not the pattern files, are licensed under the GPLv3 with the exception of CodeCompletion.hx, which is MIT.
* The [noUiSlider](https://github.com/leongersen/noUiSlider) settings sliders are WTFPL.
* The [three.js](https://github.com/mrdoob/three.js/) library is MIT.