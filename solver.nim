
import os, sets, strformat, strutils, times
import vmath

const
  dungeonWidth = 8
  dungeonHeight = 8

  nNorth = ivec2(0, -1)
  nEast = ivec2(-1, 0)
  nSouth = ivec2(0, 1)
  nWest = ivec2(1, 0)

  cHallway = ' '
  cWall = '#'
  cUnknown = '.'
  cMonster = 'M'
  cTreasure = 'T'

type
  Dungeon = ref object
    colCount: array[dungeonWidth, int]
    rowCount: array[dungeonHeight, int]
    grid: array[dungeonWidth * dungeonHeight, char]
    solved: bool

proc ivec2(x, y: SomeNumber): IVec2 {.inline.} =
  ## Integer short cut for creating vectors.
  ivec2(x.int32, y.int32)

proc `$`(self: Dungeon): string =
  result = "  | "
  for col in 0 ..< dungeonWidth:
    result &= $self.colCount[col]
    result &= " "
  result &= "\n--------------------\n"
  for row in 0 ..< dungeonHeight:
    result &= $self.rowCount[row]
    result &= " | "
    for col in 0 ..< dungeonWidth:
      result &= $self.grid[row * dungeonWidth + col]
      result &= " "
    result &= "\n"

proc initDungeon(self: Dungeon, dungeonStr: string) =
  let lines = dungeonStr.splitLines()
  doAssert(lines.len == dungeonHeight + 1,
      fmt"File should be {dungeonHeight + 1} lines")
  let headerLine = lines[0].strip()
  doAssert(headerLine.len == dungeonWidth,
      fmt"Header should be {dungeonWidth} characters long")
  for col in 0 ..< dungeonWidth:
    self.colCount[col] = headerLine[col].int - '0'.int
  for row in 0 ..< dungeonHeight:
    let line = lines[row + 1].strip()
    doAssert(line.len == dungeonWidth + 1,
        fmt"Row should be {dungeonWidth + 1} characters long")
    self.rowCount[row] = line[0].int - '0'.int
    for col in 0 ..< dungeonWidth:
      let cell = line[col + 1]
      doAssert(cell in [cHallway, cWall, cMonster, cTreasure, cUnknown])
      self.grid[dungeonWidth * row + col] = cell
  self.solved = false

proc initFromDungeonFile(self: Dungeon, filename: string) =
  let dungeonStr = readFile(filename)
  self.initDungeon(dungeonStr)

proc isOnGrid(pos: IVec2): bool =
  pos.x >= 0 and pos.x < dungeonWidth and pos.y >= 0 and pos.y < dungeonHeight

proc cell(self: Dungeon, pos: IVec2): char =
  self.grid[dungeonWidth * pos.y + pos.x]

proc cell(self: Dungeon, x, y: int): char =
  self.grid[dungeonWidth * y + x]

proc setCell(self: Dungeon, pos: IVec2, val: char) =
  self.grid[dungeonWidth * pos.y + pos.x] = val

iterator allPos(width: int = dungeonWidth, height: int = dungeonHeight): IVec2 =
  for row in 0 ..< height:
    for col in 0 ..< width:
      yield ivec2(col, row)

iterator allNeighbours(pos: IVec2): IVec2 =
  for neightbourDir in [nNorth, nEast, nSouth, nWest]:
    yield pos + neightbourDir

proc countNeighbourWalls(self: Dungeon, pos: IVec2): int =
  for neighbourPos in pos.allNeighbours():
    if not neighbourPos.isOnGrid() or self.cell(neighbourPos) == cWall:
      inc result

proc countNeighbourCells(self: Dungeon, pos: IVec2, cell: char): int =
  for neighbourPos in pos.allNeighbours():
    if neighbourPos.isOnGrid() and self.cell(neighbourPos) == cell:
      inc result

proc countIslands(self: Dungeon): int =
  # Counts the number of contiguous shapes in a 2D grid.

  # Collect all land points in the grid
  var landPos: HashSet[IVec2]
  for pos in allPos():
    if self.cell(pos) != cWall:
      landPos.incl(pos)

  proc removeIsland(pos: IVec2): int =
    if landPos.len == 0:
      return 0
    if pos notin landPos:
      return 0

    landPos.excl(pos)
    inc result

    for neighbourPos in pos.allNeighbours():
      result += removeIsland(neighbourPos)

  # Remove islands until there are none left
  while landPos.len > 0:
    let pos = landPos.pop()
    landPos.incl(pos) # peep: pop and put it back
    let hits = removeIsland(pos)
    if hits == 0:
      break
    inc result

proc countCellsOnRow(self: Dungeon, cell: char, row: int): int =
  for col in 0 ..< dungeonWidth:
    if self.cell(col, row) == cell:
      inc result

proc countCellsOnCol(self: Dungeon, cell: char, col: int): int =
  for row in 0 ..< dungeonHeight:
    if self.cell(col, row) == cell:
      inc result

proc findTreasures(self: Dungeon): seq[IVec2] =
  for pos in allPos():
    if self.cell(pos) == cTreasure:
      result.add(pos)

iterator allTreasureRoomTiles(startPos: IVec2): IVec2 =
  for row in 0 .. 2:
    for col in 0 .. 2:
      yield startPos + ivec2(col, row)

proc isEmpty3x3(self: Dungeon, startPos: IVec2): bool =
  for pos in allTreasureRoomTiles(startPos):
    if not pos.isOnGrid() or self.cell(pos) notin [cHallway, cTreasure]:
      return false
  return true

proc findTreasureRoomEntrances(self: Dungeon, treasureRoomPos: IVec2): seq[IVec2] =
  for offset in 0 .. 2:
    for entranceOffset in [ivec2(offset, -1), ivec2(offset, 3), ivec2(-1,
        offset), ivec2(3, offset)]:
      let entrancePos = treasureRoomPos + entranceOffset
      if entrancePos.isOnGrid() and self.cell(entrancePos) != cWall:
        result.add(entrancePos)

proc findTreasureRoom(self: Dungeon, treasurePos: IVec2): seq[IVec2] =
  for offsetX in -2 .. 0:
    for offsetY in -2 .. 0:
      let startPos = treasurePos + ivec2(offsetX, offsetY)
      if self.isEmpty3x3(startPos):
        result.add(startPos)

iterator all2x2Tiles(startPos: IVec2): IVec2 =
  for row in 0 .. 1:
    for col in 0 .. 1:
      yield startPos + ivec2(col, row)

proc checkFullValidity(self: Dungeon, verbose = false): bool =
  # count rows
  for row in 0 ..< dungeonHeight:
    let walls = self.countCellsOnRow(cWall, row)
    if walls != self.rowCount[row]:
      if verbose:
        echo fmt"ERR: Invalid number of walls on row {row}: expected {self.rowCount[row]}, actual {walls}"
      return false

  # count columns
  for col in 0 ..< dungeonWidth:
    let walls = self.countCellsOnCol(cWall, col)
    if walls != self.colCount[col]:
      if verbose:
        echo fmt"ERR: Invalid number of walls on col {col}: expected {self.colCount[col]}, actual {walls}"
      return false

  # all dead ends are monsters, all monsters are on dead ends
  for pos in allPos():
    let
      cellVal = self.cell(pos)
      hasMonster = (cellVal == cMonster)
      isDeadEnd = (cellVal != cWall and self.countNeighbourWalls(pos) == 3)
    if hasMonster and not isDeadEnd:
      if verbose:
        echo fmt"ERR: monster not on dead-end at {pos}"
      return false
    if not hasMonster and isDeadEnd:
      if verbose:
        echo fmt"ERR: no monster on dead-end at {pos}"
      return false

  # treasure room always 3x3 with single entrance
  let treasures = self.findTreasures()
  # echo "Treasure: ", treasures
  var treasureTiles: HashSet[IVec2]
  for treasurePos in treasures:
    let startPoses = self.findTreasureRoom(treasurePos)
    if startPoses.len != 1:
      if verbose:
        echo fmt"ERR: only a single startPos allowed per treasureroom, but found {startPoses.len} for {treasurePos}: {startPoses}"
      return false
    for startPos in startPoses:
      let entrances = self.findTreasureRoomEntrances(startPos)
      if entrances.len != 1:
        if verbose:
          echo fmt"ERR: only a single entrance allowed per treasureroom, but found {entrances.len} for {treasurePos}: {entrances}"
        return false
      for pos in allTreasureRoomTiles(startPos):
        treasureTiles.incl(pos)

  # hallways always one square wide; no 2x2 blocks outside treasure rooms
  for startPos in allPos(dungeonWidth - 1, dungeonHeight - 1):
    block wideHallway:
      for pos in all2x2Tiles(startPos):
        if pos in treasureTiles or self.cell(pos) == cWall:
          break wideHallway
      if verbose:
        echo fmt"ERR: hallway 2x2 block found on {startPos}"
      return false

  # all unshaded squares connected into single continuous shape
  let islands = self.countIslands()
  if islands != 1:
    if verbose:
      echo fmt"ERR: all unshaded squares connected into single continuous shape, but found {islands} islands."
    return false

  # yay
  result = true

proc checkQuickValidity(self: Dungeon, c: char, x, y: int): bool =
  let
    pos = ivec2(x, y)
    rowWalls = self.countCellsOnRow(cWall, y)
    rowUnknowns = self.countCellsOnRow(cUnknown, y)
    placeWall = if c == cWall: 1 else: 0
    minRowWalls = rowWalls + placeWall
    maxRowWalls = minRowWalls + rowUnknowns - 1

  if not between(self.rowCount[y], minRowWalls, maxRowWalls):
    # echo fmt"!ROW {minRowWalls} <= {self.rowCount[y]} <= {maxRowWalls}"
    return false

  let
    colWalls = self.countCellsOnCol(cWall, x)
    colUnknowns = self.countCellsOnCol(cUnknown, x)
    minColWalls = colWalls + placeWall
    maxColWalls = minColWalls + colUnknowns - 1

  if not between(self.colCount[x], minColWalls, maxColWalls):
    # echo fmt"!COL {minColWalls} <= {self.colCount[x]} <= {maxColWalls}"
    return false

  # all dead ends are monsters, all monsters are on dead ends
  for neighbourPos in allNeighbours(pos):
    if neighbourPos.isOnGrid() and self.cell(neighbourPos) != cUnknown:
      let
        cellVal = self.cell(neighbourPos)
        hasMonster = (cellVal == cMonster)
        neighbourWalls = self.countNeighbourWalls(neighbourPos)
        neighbourUnknowns = self.countNeighbourCells(neighbourPos, cUnknown)
        minNeighbourWalls = neighbourWalls + placeWall
        maxNeighbourWalls = minNeighbourWalls + neighbourUnknowns - 1
        isDeadEnd = (cellVal != cWall and minNeighbourWalls == 3 and neighbourUnknowns < 2)
      if hasMonster and not between(3, minNeighbourWalls, maxNeighbourWalls):
        # echo fmt"!NEIGHBOUR {minNeighbourWalls} <= 3 <= {maxNeighbourWalls}"
        return false
      if not hasMonster and isDeadEnd:
        return false

  result = true

var
  falsePositives = 0

proc placeCell(self: Dungeon, pos: int, verbose = false) =
  if self.solved:
    return
  if pos == dungeonWidth * dungeonHeight:
    if self.checkFullValidity(verbose):
      self.solved = true
    else:
      if verbose:
        echo $self
      inc falsePositives
    return
  if self.grid[pos] != cUnknown:
    self.placeCell(pos + 1, verbose)
    return
  for cell in [cHallway, cWall]:
    if self.checkQuickValidity(cell, pos mod dungeonWidth, pos div dungeonWidth):
      self.grid[pos] = cell
      self.placeCell(pos + 1, verbose)
      if self.solved:
        return
      self.grid[pos] = cUnknown

proc solve(self: Dungeon, verbose = false) =
  if verbose:
    echo "Starting grid:\n", $self
  self.placeCell(0, false)
  if verbose:
    if self.solved:
      echo "Solution:\n", $self
    else:
      echo "Unsolvable!"

proc main() =
  if paramCount() < 1:
    echo "Usage: solver <dungeon.txt>"
    quit(1)

  let verbose = paramCount() == 1

  for i in 1..paramCount():
    let dungeonFile = paramStr(i)
    if verbose:
      echo "Loading ", dungeonFile
    var puzzle = Dungeon()
    initFromDungeonFile(puzzle, dungeonFile)

    falsePositives = 0
    let startTime = cpuTime()
    solve(puzzle, verbose)
    echo dungeonFile
    echo "Solved: ", puzzle.solved
    echo "cpuTime: ", cpuTime() - startTime
    echo "False positives: ", falsePositives
    echo ""

main()
