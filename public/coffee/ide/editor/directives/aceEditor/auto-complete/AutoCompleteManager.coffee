define [
	"ide/editor/directives/aceEditor/auto-complete/SuggestionManager"
	"ide/editor/directives/aceEditor/auto-complete/Snippets"
	"ace/ace"
	"ace/ext-language_tools"
], (SuggestionManager, Snippets) ->
	Range = ace.require("ace/range").Range

	getLastCommandFragment = (lineUpToCursor) ->
		if m = lineUpToCursor.match(/(\\[^\\ ]+)$/)
			return m[1]
		else
			return null

	class AutoCompleteManager
		constructor: (@$scope, @editor) ->
			@suggestionManager = new SuggestionManager()

			@$scope.$watch "autoComplete", (autocomplete) =>
				if autocomplete
					@enable()
				else
					@disable()

			onChange = (change) =>
				@onChange(change)

			@editor.on "changeSession", (e) =>
				e.oldSession.off "change", onChange
				e.session.on "change", onChange

		enable: () ->
			console.log "ENABLE auto complete"
			@editor.setOptions({
				enableBasicAutocompletion: true,
				enableSnippets: true,
				enableLiveAutocompletion: true
			})

			@editor.completers = [@suggestionManager]

		disable: () ->
			@editor.setOptions({
				enableBasicAutocompletion: false,
				enableSnippets: false
			})

		_patched: false
		monkeyPatch: (editor) ->
			if @_patched
				return
			lang = ace.require('ace/lib/lang')
			editor.completer.changeTimer = lang.delayedCall(
				() ->
					editor.completer.updateCompletions()
			)
			@_patched = true

		triggerAutocomplete: (editor) ->
			setTimeout () =>
				editor.execCommand("startAutocomplete")
				@monkeyPatch(editor)
			, 0

		onChange: (change) ->
			cursorPosition = @editor.getCursorPosition()
			end = change.end
			# Check that this change was made by us, not a collaborator
			# (Cursor is still one place behind)
			if end.row == cursorPosition.row and end.column == cursorPosition.column + 1
				if change.action == "insert"
					range = new Range(end.row, 0, end.row, end.column)
					lineUpToCursor = @editor.getSession().getTextRange(range)
					commandFragment = getLastCommandFragment(lineUpToCursor)
					console.log ">> onChange: #{lineUpToCursor} - #{commandFragment}"

					if commandFragment? and commandFragment.length > 2
						@triggerAutocomplete(editor)

					# fire autocomplete if line ends in `some_identifier.`
					if lineUpToCursor.match(/(\w+)\.$/)
						@triggerAutocomplete(editor)
