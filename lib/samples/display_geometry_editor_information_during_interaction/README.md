# Display geometry editor information during interaction

Use the geometry editor to see information about the geometry editor's previewed geometry during an editing interaction.

![DisplayGeometryEditorInformationDuringInteraction](display_geometry_editor_information_during_interaction.png)

## Use case

The geometry editor can provide information about the geometry being created or edited during an interaction. This information can be used to give feedback to the user to show the effect of the interaction on the geometry.

## How to use the sample

Tap a graphic to edit its geometry by moving, rotating, or scaling the geometry. During the interaction, information about the geometry will be displayed to provide feedback to the user.

Use the buttons in the settings view to undo or redo changes made to the geometry and the cancel and done buttons to discard and save changes, respectively.

## How it works

1. Create a `GeometryEditor` and set it to the `ArcGISMapViewController.geometryEditor`.
2. Add an event handler to listen to `GeometryEditor.onInteractionPreviewChanged`.
    * This event can be used to get information on the state of the geometry during an interaction with the `GeometryEditorInteractionPreview` parameter.
        * The `previewGeometry` represents the geometry's state at that moment.
        * The `interactionType` can be used to determine the type of interaction that is occurring (`create`, `move`, `rotate`, `scale`).
3. Configure a `VertexTool` with an `InteractionConfiguration` and assign it to `GeometryEditor.tool`.
4. Start the `GeometryEditor` using `GeometryEditor.startWithGeometry(Geometry)` to edit the geometry of an identified `Graphic`.
    * To identify the `Graphic` use `ArcGISMapViewController.identifyGraphicsOverlay(...)` and get the first `Graphic` from the `IdentifyGraphicsOverlayResult.graphics` list.
5. Listen to `GeometryEditor.onCanUndoChanged` and `GeometryEditor.onCanRedoChanged` to check if undo and redo are possible during an editing session. If possible, use `GeometryEditor.undo()` and `GeometryEditor.redo()`.
6. Call `GeometryEditor.stop()` to finish the editing session and store the `Graphic`. The `GeometryEditor` does not automatically handle the visualization of a geometry output from an editing session. This must be done manually by propagating the geometry returned into a `Graphic` added to a `GraphicsOverlay`.
    * To update the geometry underlying an existing `Graphic` in the `GraphicsOverlay`:
        * Replace the existing `Graphic`'s `geometry` property with the geometry returned by the `GeometryEditor.stop()` method.

## Relevant API

* Geometry
* GeometryEditor
* GeometryEditor.onInteractionPreviewChanged
* GeometryEditorInteractionPreview
* GeometryEditorInteractionType
* Graphic
* GraphicsOverlay

## Additional information

The `GeometryEditor.onInteractionPreviewChanged` event fires continuously during an interaction, therefore it's not recommended to use it as a trigger for resource intensive actions.

## Tags

draw, edit, geometry editor, interaction preview
