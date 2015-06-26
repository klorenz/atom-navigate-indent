NavigateIndentView = require './navigate-indent-view'
{CompositeDisposable} = require 'atom'

module.exports = NavigateIndent =
  navigateIndentView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @navigateIndentView = new NavigateIndentView(state.navigateIndentViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @navigateIndentView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'navigate-indent:next': => @goToIndentationNext {}
    @subscriptions.add atom.commands.add 'atom-workspace', 'navigate-indent:prev': => @goToIndentationPrev {}
    @subscriptions.add atom.commands.add 'atom-workspace', 'navigate-indent:up'  : => @goToIndentationUp {}
    @subscriptions.add atom.commands.add 'atom-workspace', 'navigate-indent:down': => @goToIndentationDown {}

    @subscriptions.add atom.commands.add 'atom-workspace', 'navigate-indent:select-next': => @goToIndentationNext select: on
    @subscriptions.add atom.commands.add 'atom-workspace', 'navigate-indent:select-prev': => @goToIndentationPrev select: on
    @subscriptions.add atom.commands.add 'atom-workspace', 'navigate-indent:select-up'  : => @goToIndentationUp   select: on
    @subscriptions.add atom.commands.add 'atom-workspace', 'navigate-indent:select-down': => @goToIndentationDown select: on

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @navigateIndentView.destroy()

  serialize: ->
    navigateIndentViewState: @navigateIndentView.serialize()

  toggle: ->
    console.log 'NavigateIndent was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

  getNextNonBlankRow: (editor, row) ->
    editor.getBuffer().nextNonBlankRow(row)

  getPrevNonBlankRow: (editor, row) ->
    editor.getBuffer().previousNonBlankRow(row)

  goToIndentationNext: ({select}) ->
    editor   = atom.workspace.getActiveTextEditor()
    lastLine = editor.getLineCount() - 1

    for selection in editor.getSelectionsOrderedByBufferPosition()
      row = selection.getBufferRowRange()[1]
      cursor = selection.cursor

      indentation = editor.indentationForBufferRow cursor.getBufferRow()

      while row = @getNextNonBlankRow editor, row
        rowIndentation = editor.indentationForBufferRow row

        if rowIndentation == indentation
          if select
            startRow = endRow = row
            indentation = editor.indentationForBufferRow row
            while endRow = @getNextNonBlankRow editor, endRow
              if indentation > editor.indentationForBufferRow endRow
                endRow = @getPrevNonBlankRow editor, endRow
                break

            # transforms startRow and EndRow to screenrows?

            cursor.setBufferPosition [startRow, 0]
            selection.selectDown endRow-startRow+1
            #selection.setBufferRange [[startRow,0], [endRow, 0]]

          else
            cursor.setBufferPosition [row, 0]
            cursor.moveToFirstCharacterOfLine()
          break

        if rowIndentation < indentation
          unless select
            cursor.setBufferPosition [row, 0]
            cursor.moveToFirstCharacterOfLine()
            break

  goToIndentationDown: ({select}) ->
    editor   = atom.workspace.getActiveTextEditor()
    lastLine = editor.getLineCount() - 1

    for selection in editor.getSelectionsOrderedByBufferPosition()
      row = selection.getBufferRowRange()[1]
      cursor = selection.cursor

      indentation = editor.indentationForBufferRow cursor.getBufferRow()

      while row = @getNextNonBlankRow editor, row
        rowIndentation = editor.indentationForBufferRow row

        if rowIndentation > indentation
          if select
            startRow = endRow = row
            indentation = editor.indentationForBufferRow row
            while endRow = @getNextNonBlankRow editor, endRow
              if indentation > editor.indentationForBufferRow endRow
                endRow = @getPrevNonBlankRow editor, endRow
                break

            # transforms startRow and EndRow to screenrows?

            cursor.setBufferPosition [startRow, 0]
            selection.selectDown endRow-startRow+1
            #selection.setBufferRange [[startRow,0], [endRow, 0]]

          else
            nextRow = row

            while nextRow = @getNextNonBlankRow editor, nextRow
              indent = editor.indentationForBufferRow nextRow
              if rowIndentation != indent
                nextRow = @getPrevNonBlankRow editor, nextRow
                break

            cursor.setBufferPosition [nextRow, 0]
            cursor.moveToFirstCharacterOfLine()
          break

        if rowIndentation < indentation
          unless select
            cursor.setBufferPosition [row, 0]
            cursor.moveToFirstCharacterOfLine()
            break

  goToIndentationUp: ({select}) ->
    editor   = atom.workspace.getActiveTextEditor()
    lastLine = editor.getLineCount() - 1

    # TODO merge expanded selections if selections overlap

    newSelections = []

    updateSelections = (selection, startRow, endRow) =>
      result = [ selection ]

      selection.cursor.setBufferPosition [startRow, 0]
      selection.selectDown endRow-startRow+1

      for sel in newSelections
        if sel.intersectsWith selection
          selection.merge sel
        else
          result.push sel

      newSelections = result


    for selection in editor.getSelectionsOrderedByBufferPosition()
      row = selection.getBufferRowRange()[0]
      console.log "=== selection", row
      cursor = selection.cursor

      indentation = editor.indentationForBufferRow row
      console.log "indentation", indentation

      while row = @getPrevNonBlankRow(editor, row)
        rowIndentation = editor.indentationForBufferRow row
        console.log "rowIndenation", rowIndentation, "indentation", indentation
        if rowIndentation < indentation
          if select
            # if selection is empty, select only text on this indentation level

            if selection.getBufferRange().isEmpty()
              row = @getNextNonBlankRow(editor, row)

            console.log "selected", editor.lineTextForBufferRow row
            startRow = endRow = row
            indent = editor.indentationForBufferRow row
            console.log "indent", indent

            foundStartRow = false
            while startRow = @getPrevNonBlankRow(editor, startRow)
              console.log "startRow?", editor.lineTextForBufferRow startRow

              if indent > editor.indentationForBufferRow startRow
                startRow = @getNextNonBlankRow editor, startRow
                foundStartRow = true
                console.log "startRow", startRow
                break

            unless foundStartRow
              startRow = 0

            foundEndRow = false
            while endRow = @getNextNonBlankRow(editor, endRow)
              console.log "endRow?", editor.lineTextForBufferRow endRow
              if indent > editor.indentationForBufferRow endRow
                endRow = @getPrevNonBlankRow editor, endRow
                foundEndRow = true
                console.log "endRow", startRow
                break

            unless foundEndRow
              endRow = lastLine

            cursor.setBufferPosition [startRow, 0]
            selection.selectDown endRow-startRow+1

          else
            cursor.setBufferPosition [row, 0]
            cursor.moveToFirstCharacterOfLine()
          break

  goToIndentationPrev: ({select}) ->
    editor   = atom.workspace.getActiveTextEditor()
    lastLine = editor.getLineCount() - 1

    for selection in editor.getSelectionsOrderedByBufferPosition()
      row = selection.getBufferRowRange()[0]
      console.log "=== selection", row
      cursor = selection.cursor

      indentation = editor.indentationForBufferRow row
      console.log "indentation", indentation

      while row = @getPrevNonBlankRow(editor, row)
        rowIndentation = editor.indentationForBufferRow row
        console.log "rowIndenation", rowIndentation, "indentation", indentation
        if rowIndentation == indentation
          if select
            # if selection is empty, select only text on this indentation level

            if selection.getBufferRange().isEmpty()
              row = @getNextNonBlankRow(editor, row)

            console.log "selected", editor.lineTextForBufferRow row
            startRow = endRow = row
            indent = editor.indentationForBufferRow row
            console.log "indent", indent

            foundStartRow = false
            while startRow = @getPrevNonBlankRow(editor, startRow)
              console.log "startRow?", editor.lineTextForBufferRow startRow

              if indent > editor.indentationForBufferRow startRow
                startRow = @getNextNonBlankRow editor, startRow
                foundStartRow = true
                console.log "startRow", startRow
                break

            if not foundStartRow
              startRow = 0

            foundEndRow = false
            while endRow = @getNextNonBlankRow(editor, endRow)
              if indent > editor.indentationForBufferRow endRow
                endRow = @getPrevNonBlankRow editor, endRow
                foundEndRow = true
                break

            if not foundEndRow
              endRow = lastLine

            cursor.setBufferPosition [startRow, 0]
            selection.selectDown endRow-startRow+1

          else
            cursor.setBufferPosition [row, 0]
            cursor.moveToFirstCharacterOfLine()
          break

        if rowIndentation < indentation
          unless select
            cursor.setBufferPosition [row, 0]
            cursor.moveToFirstCharacterOfLine()
            break


  goToIndendation: ({select, getNextRow, indentCondition, getPosition, selectBlock}) ->
    editor   = atom.workspace.getActiveTextEditor()
    lastLine = editor.getLineCount() - 1

    for selection in editor.getSelectionsOrderedByBufferPosition()
      pos    = getPosition selection
      cursor = selection.cursor
      row    = pos.row

      indentation = editor.indentationForBufferRow row

      while row = getNextRow(editor, row)

        if indentCondition(indentation, editor.indentationForBufferRow(row))
          if select
            if selectBlock
              startRow    = endRow = row
              indentation = editor.indentationForBufferRow row

              while endRow = getNextRow(editor, endRow)
                if indentation != editor.indentationForBufferRow endRow
                  break

              if startRow > endRow
                [startRow, endRow] = [endRow, startRow]

              selection.selectToBufferPosition([startRow,0])
              selection.selectToBufferPosition([endRow,0])

          else
            cursor.setBufferPosition [row, pos.column]
          break
