Emitter = require '../src/emitter'

describe "Behavior", ->
  [emitter, behavior] = []

  beforeEach ->
    emitter = new Emitter
    behavior = emitter.signal('a').toBehavior(1)

  describe "::toBehavior()", ->
    it "returns itself because it's already a behavior", ->
      expect(behavior.toBehavior()).toBe behavior

  describe "::changes()", ->
    it "emits all changes to the behavior, but not its initial value", ->
      behavior.changes().onValue handler = jasmine.createSpy("handler")
      expect(handler).not.toHaveBeenCalled()
      emitter.emit 'a', 7
      expect(handler).toHaveBeenCalledWith(7)
      handler.reset()
      emitter.emit 'a', 8
      expect(handler).toHaveBeenCalledWith(8)

  describe "::filter(predicate)", ->
    it "returns a new behavior that only changes to values matching the given predicate", ->
      values = []
      behavior.filter((value) -> value > 5).onValue (v) -> values.push(v)

      expect(values).toEqual [undefined] # initial value did not match predicate
      emitter.emit('a', i) for i in [0..10]
      expect(values).toEqual [undefined].concat([6..10])

      # now the value of the source behavior is 10, so the initial value passes the predicate
      values = []
      behavior.filter((value) -> value > 5).onValue (v) ->
        debugger
        values.push(v)
      expect(values).toEqual [10]

  describe "::map(fn)", ->
    it "returns a new signal that emits events that are transformed by the given function", ->
      values = []
      behavior.map((value) -> value + 2).onValue (v) -> values.push(v)

      expect(values).toEqual [3]
      emitter.emit('a', i) for i in [0..10]
      expect(values).toEqual [3].concat([2..12])

  describe "::skipUntil(valueOrPredicate)", ->
    describe "when passed a value", ->
      it "skips all values until encountering a value that matches the target value", ->
        values = []
        behavior.skipUntil(5).onValue (v) -> values.push(v)
        expect(values).toEqual [undefined]
        emitter.emit 'a', 0
        emitter.emit 'a', 10
        emitter.emit 'a', 5
        emitter.emit 'a', 4
        emitter.emit 'a', 6
        expect(values).toEqual [undefined, 5, 4, 6]

    describe "when passed a predicate", ->
      it "skips all values until the predicate obtains", ->
        values = []
        behavior.skipUntil((v) -> v > 5).onValue (v) -> values.push(v)
        expect(values).toEqual [undefined]
        emitter.emit 'a', 0
        emitter.emit 'a', 10
        emitter.emit 'a', 5
        emitter.emit 'a', 4
        emitter.emit 'a', 6
        expect(values).toEqual [undefined, 10, 5, 4, 6]

  describe "::scan(initialValue, fn)", ->
    it "returns a behavior yielding the given initial value, then a new value produced by calling the given function with the previous and new values for every change", ->
      values = []
      behavior = behavior.scan 0, (oldValue, newValue) -> oldValue + newValue
      behavior.onValue (value) -> values.push(value)

      expect(values).toEqual [1]
      emitter.emit 'a', i for i in [1..5]
      expect(values).toEqual [1, 2, 4, 7, 11, 16]

  describe "::diff(initialValue, fn)", ->
    it "returns a behavior yielding the result of the function for previous and new value of the signal", ->
      values = []
      behavior = behavior.diff 0, (oldValue, newValue) -> oldValue + newValue
      behavior.onValue (value) -> values.push(value)

      expect(values).toEqual [1]
      emitter.emit 'a', i for i in [1..5]
      expect(values).toEqual [1, 2, 3, 5, 7, 9]

  describe "::distinctUntilChanged()", ->
    it "returns a signal that yields a value only when the source signal emits a different value from the previous", ->
      values = []
      behavior.distinctUntilChanged().onValue (v) -> values.push(v)

      expect(values).toEqual [1]
      emitter.emit('a', 1)
      emitter.emit('a', 1)
      expect(values).toEqual [1]
      emitter.emit('a', 2)
      emitter.emit('a', 2)
      expect(values).toEqual [1, 2]

  describe "::becomes(valueOrPredicate)", ->
    describe "when passed a value", ->
      it "emits true when the behavior changes to the target value and false when it subsequently changes to a different value", ->
        behavior.becomes(5).onValue handler = jasmine.createSpy("handler")
        expect(handler).not.toHaveBeenCalled()
        emitter.emit 'a', 4
        expect(handler).not.toHaveBeenCalled()
        emitter.emit 'a', 5
        expect(handler).toHaveBeenCalledWith(true)
        handler.reset()
        emitter.emit 'a', 5
        expect(handler).not.toHaveBeenCalled()
        emitter.emit 'a', 10
        expect(handler).toHaveBeenCalledWith(false)

    describe "when passed a predicate", ->
      it "emits true when the behavior changes to a value matching the predicate and false when subsquently changes to a value that does not match", ->
        behavior.becomes((v) -> v > 5).onValue handler = jasmine.createSpy("handler")
        expect(handler).not.toHaveBeenCalled()
        emitter.emit 'a', 4
        expect(handler).not.toHaveBeenCalled()
        emitter.emit 'a', 10
        expect(handler).toHaveBeenCalledWith(true)
        handler.reset()
        emitter.emit 'a', 8
        expect(handler).not.toHaveBeenCalled()
        emitter.emit 'a', 4
        expect(handler).toHaveBeenCalledWith(false)

  describe "::becomes(value)", ->
    it "emits true when the behavior changes *to* the target value and false when it changes *away* from the target value", ->
      behavior.becomes(5).onValue handler = jasmine.createSpy("handler")
      expect(handler).not.toHaveBeenCalled()
      emitter.emit 'a', 4
      expect(handler).not.toHaveBeenCalled()
      emitter.emit 'a', 5
      expect(handler).toHaveBeenCalledWith(true)
      handler.reset()
      emitter.emit 'a', 5
      expect(handler).not.toHaveBeenCalled()
      emitter.emit 'a', 10
      expect(handler).toHaveBeenCalledWith(false)
