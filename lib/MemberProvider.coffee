AbstractProvider = require './AbstractProvider'

module.exports =

##*
# Provides annotations for member methods that are overrides or interface implementations.
##
class MethodProvider extends AbstractProvider
    ###*
     * @inheritdoc
    ###
    regex: /^(\s*(?:public|protected|private)\s+function\s+)(\w+)\s*\(/g

    methodRegex: /^(\s*(?:public|protected|private)\s+function\s+)(\w+)\s*\(/g


    ###*
     * @inheritdoc
    ###
    registerAnnotations: (editor) ->
        super(editor)



        currentClass = @service.determineFullClassName(editor)

        return if not currentClass

        currentClassInfo = @service.getClassInfo(currentClass)

        for name, method of currentClassInfo.methods
            continue if not method.override and not method.implementation

            regex = new RegExp("^(\\s*)((?:public|protected|private)\\s+function\\s+" + name + "\\s*)\\(")

            editor.getBuffer().scan(regex, (matchInfo) =>
                # Remove the spacing from the range.
                matchInfo.range.start.column += matchInfo.match[1].length

                @placeAnnotation(editor, matchInfo.range, @extractAnnotationInfo(method))

                stop()
            )


        for name, property of currentClassInfo.properties
            continue if not property.override

            regex = new RegExp("^(\\s*)(?:public|protected|private)\\s+\\$" + name + "\\s+")

            editor.getBuffer().scan(regex, (matchInfo) =>
                # Remove the spacing from the range.
                matchInfo.range.start.column += matchInfo.match[1].length

                @placeAnnotation(editor, matchInfo.range, @extractAnnotationInfo(property))

                stop()
            )

    ###*
     * @inheritdoc
    ###
    extractAnnotationInfo: (context) ->
        extraData = null
        tooltipText = ''
        lineNumberClass = ''

        # NOTE: We deliberately show the declaring class here, not the structure (which could be a trait).
        if context.override
            extraData = context.override
            lineNumberClass = 'override'
            tooltipText = 'Overrides method from ' + extraData.declaringClass.name

        else
            extraData = context.implementation
            lineNumberClass = 'implementation'
            tooltipText = 'Implements method for ' + extraData.declaringClass.name

        return {
            lineNumberClass : lineNumberClass
            tooltipText     : tooltipText
            extraData       : extraData
        }

    ###*
     * @inheritdoc
    ###
    handleMouseClick: (event, editor, annotationInfo) ->
        atom.workspace.open(annotationInfo.extraData.declaringStructure.filename, {
            initialLine    : annotationInfo.extraData.startLine - 1,
            searchAllPanes : true
        })

    ###*
     * @inheritdoc
    ###
    removePopover: () ->
        if @attachedPopover
            @attachedPopover.dispose()
            @attachedPopover = null