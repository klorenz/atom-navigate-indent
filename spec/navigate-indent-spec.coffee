NavigateIndent = require '../lib/navigate-indent'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "NavigateIndent", ->
  [workspaceElement, activationPromise, editor, editorElement, cursorChanged] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('navigate-indent')

    filename = "#{__dirname}/fixtures/foo.py"

    cursorChanged = jasmine.createSpy('cursor-changed')

    waitsForPromise ->
      activationPromise

    waitsForPromise ->
      atom.workspace.open(filename).then (o) ->
        editor = o
        editorElement = atom.views.getView(editor)
        editor.onDidChangeCursorPosition cursorChanged

  it "can go to next indentation of same level (next)", ->
    editor.setCursorBufferPosition([0,0])
    atom.commands.dispatch editorElement, 'navigate-indent:next'

    expect(cursorChanged).toHaveBeenCalled()
    expect(editor.getCursorBufferPosition().toArray()).toEqual [5,0]


  it "can go to prev indentation of same level (prev)", ->
    editor.setCursorBufferPosition([10,7])
    atom.commands.dispatch editorElement, 'navigate-indent:prev'

    expect(cursorChanged).toHaveBeenCalled()
    expect(editor.getCursorBufferPosition().toArray()).toEqual [8,7]

  fit "can go to next indentation level (down)", ->
    editor.setCursorBufferPosition([6,4])

    atom.commands.dispatch editorElement, 'navigate-indent:down'

    expect(cursorChanged).toHaveBeenCalled()
    expect(editor.getCursorBufferPosition().toArray()).toEqual [9,4]

  it "can go to prev indentation level (up)", ->
    editor.setCursorBufferPosition([10,4])

    atom.commands.dispatch editorElement, 'navigate-indent:up'

    expect(cursorChanged).toHaveBeenCalled()
    expect(editor.getCursorBufferPosition().toArray()).toEqual [5,4]

  #it "can go to next indentation of same level with multiple cursors", ->
