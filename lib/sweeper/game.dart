class Game {
  final Field field;
  final Array2d<SquareState> _states;
  final EventHandle<EventArgs> _updatedEvent;

  GameState _state;
  int _minesLeft;
  int _revealsLeft;

  Game(Field field) :
    this.field = field,
    _state = GameState.notStarted,
    _states = new Array2d<SquareState>(field.cols, field.rows, SquareState.hidden),
    _updatedEvent = new EventHandle<EventArgs>() {
    assert(field != null);
    _minesLeft = field.mineCount;
    _revealsLeft = field.size - field.mineCount;
  }

  int get minesLeft() => _minesLeft;

  int get revealsLeft() => _revealsLeft;

  GameState get state() => _state;

  EventRoot get updated() => _updatedEvent;

  SquareState getSquareState(int x, int y) => _states.get(x,y);

  void setFlag(int x, int y, bool value) {
    _ensureStarted();
    assert(value != null);

    final currentSS = _states.get(x,y);
    if(value) {
      require(currentSS == SquareState.hidden);
      _states.set(x,y,SquareState.flagged);
      _minesLeft--;
    } else {
      require(currentSS == SquareState.flagged);
      _states.set(x,y,SquareState.hidden);
      _minesLeft++;
    }
    _update();
  }

  int reveal(int x, int y) {
    _ensureStarted();
    final currentSS = _states.get(x,y);
    require(currentSS != SquareState.flagged, 'Cannot reveal a flagged square');

    int reveals = 0;

    // normal reveal
    if(currentSS == SquareState.hidden) {
      if(field.isMine(x, y)) {
        _setLost();
      } else {
        reveals = _doReveal(x, y);
      }
    } else if(currentSS == SquareState.revealed) {
      // might be a 'chord' reveal
      final adjFlags = _getAdjacentFlagCount(x, y);
      final adjCount = field.getAdjacentCount(x, y);
      if(adjFlags == adjCount) {
        reveals = _doChord(x, y);
      }
    }
    _update();
    return reveals;
  }

  int _doChord(int x, int y) {
    // this does not repeat a bunch of validations that have already happened
    // be careful
    final currentSS = _states.get(x,y);
    assert(currentSS == SquareState.revealed);

    final flagged = new List<_Coord>();
    final hidden = new List<_Coord>();
    final adjCount = field.getAdjacentCount(x, y);

    bool failed = false;

    for(final c in field._getAdjacent(x, y)) {
      if(_states.get(c.x, c.y) == SquareState.hidden) {
        hidden.add(c);
        if(field.isMine(c.x, c.y)) {
          failed = true;
        }
      } else if(_states.get(c.x, c.y) == SquareState.flagged) {
        flagged.add(c);
      }
    }

    // for now we assume counts have been checked
    assert(flagged.length == adjCount);

    int reveals = 0;

    // if any of the hidden are mines, we've failed
    if(failed) {
      // TODO: assert one of the flags must be wrong, right?
      _setLost();
    } else {
      for(final c in hidden) {
        reveals += reveal(c.x, c.y);
      }
    }

    return reveals;
  }

  int _doReveal(int x, int y) {
    assert(_states.get(x,y) == SquareState.hidden);
    _states.set(x,y,SquareState.revealed);
    _revealsLeft--;
    assert(_revealsLeft >= 0);
    int revealCount = 1;
    if(_revealsLeft == 0) {
      _setState(GameState.won);
    } else if (field.getAdjacentCount(x, y) == 0) {
      for(final c in field._getAdjacent(x, y)) {
        if(_states.get(c.x, c.y) == SquareState.hidden) {
          revealCount += _doReveal(c.x, c.y);
          assert(_state == GameState.started || _state == GameState.won);
        }
      }
    }
    return revealCount;
  }

  void _setLost() {
    assert(_state == GameState.started);
    for(int x = 0; x < field.cols; x++) {
      for(int y = 0; y < field.rows; y++) {
        if(field.isMine(x, y)) {
          _states.set(x,y,SquareState.mine);
        }
      }
    }
    _setState(GameState.lost);
  }

  void _update() => _updatedEvent.fireEvent(EventArgs.empty);

  void _setState(GameState value) {
    if(_state != value) {
      _state = value;
    }
  }

  void _ensureStarted() {
    if(state == GameState.notStarted) {
      _setState(GameState.started);
    }
    assert(state == GameState.started);
  }

  int _getAdjacentFlagCount(int x, int y) {
    assert(_states.get(x,y) == SquareState.revealed);

    int val = 0;
    for(final c in field._getAdjacent(x, y)) {
      if(_states.get(c.x, c.y) == SquareState.flagged) {
        val++;
      }
    }
    return val;
  }
}
