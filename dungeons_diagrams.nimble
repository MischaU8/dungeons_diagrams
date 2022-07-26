# Package

version = "0.1.0"
author = "mischa_u"
description = "Dungeons & Diagrams solver"
license = "MIT"
srcDir = "src"
bin = @["solver"]
skipDirs = @["data"]
skipExt = @["nim"]

# Deps
requires "nim >= 1.2.6"
requires "vmath >= 1.1.4"
