# Celestial Music

by Max Bogue

Done as a final project for Music of the Spheres, a curious class with
professor Joel Kastner at RIT.  The class focused on the ancient relationship
between music and astronomy, and simultaneously covered modern techniques for
finding planets.

This project is a simple program that takes solar system structure as
input and produces an audio/visualization of that solar system.

See the `sol.json` file for the input format.

## Installation

If you don't have cabal-dev:

    cabal install cabal-dev

Clone the git repository:

    git clone git://github.com/maxbogue/Celestial-Music.git
    cd Celestial-Music

Build source (this will take a solid 5-10 minutes the first time because there
are a lot of libraries for cabal to install):

    cabal-dev install

Run:

    cabal-dev/bin/CelestialMusic sol.json
