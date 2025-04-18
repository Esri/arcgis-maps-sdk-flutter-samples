# Edit with branch versioning

Create, query and edit a specific server version using service geodatabase.

![Image of edit with branch versioning](edit_with_branch_versioning.png)

## Use case

Workflows often progress in discrete stages, with each stage requiring the allocation of a different set of resources and business rules. Typically, each stage in the overall process represents a single unit of work, such as a work order or job. To manage these, you can create a separate, isolated version and modify it. Once this work is complete, you can integrate the changes into the default version.

## How to use the sample

Once loaded, the map will zoom to the extent of the feature layer. The current version is indicated at the top of the map. Tap on "Create" to open a bottom modal sheet to specify the version information (name, access, and description). See the *Additional information* section for restrictions on the version name.

Tap "Create" to create the version with the information that you specified. Select a feature to edit an attribute and/or tap a second time anywhere on the map to relocate the point.

Tap the Switch button in the bottom right corner to switch back and forth between the version you created and the default version. Edits will automatically be applied to your version when switching to the default version.

## How it works

1. Create and load a `ServiceGeodatabase` with a feature service URL that has enabled Version Management.
2. Get the `ServiceFeatureTable` from the service geodatabase.
3. Create a `FeatureLayer` from the service feature table.
4. Create `ServiceVersionParameters` with a unique name, `VersionAccess`, and description.
    * Note - See the additional information section for more restrictions on the version name.
5. Create a new version calling `ServiceGeodatabase.createVersion` passing in the service version parameters.
6. Await  `ServiceGeodatabase.createVersion` signal to obtain the `ServiceVersionInfo` of the version created.
7. Switch to the version you have just created using `ServiceGeodatabase.switchVersion`, passing in the version name obtained from the service version info from *step 6*.
8. Select a `Feature` from the map to edit its "TYPDAMAGE" attribute and location.
9. Apply these edits to your version by calling `ServiceGeodatabase.applyEdits()`.
10. Switch back and forth between your version and the default version to see how the two versions differ.

## Relevant API

* FeatureLayer
* ServiceFeatureTable
* ServiceGeodatabase
* ServiceGeodatabase.applyEdits
* ServiceGeodatabase.createVersion
* ServiceGeodatabase.switchVersion
* ServiceGeodatabase.undoLocalEdits
* ServiceVersionInfo
* ServiceVersionParameters
* VersionAccess

## About the data

The feature layer used in this sample is [Damage to commercial buildings](https://sampleserver7.arcgisonline.com/server/rest/services/DamageAssessment/FeatureServer/0) located in Naperville, Illinois.

## Additional information

Credentials:

* Username: editor01
* Passowrd: S7#i2LWmYH75

The name of the version must meet the following criteria:

1. Must not exceed 62 characters
2. Must not include: Period (.), Semicolon (;), Single quotation mark ('), Double quotation mark (")
3. Must not include a space for the first character

* Note - the version name will have the username and a period (.) prepended to it. E.g "editor01.MyNewUniqueVersionName"

Branch versioning access permission:

1. VersionAccess.Public - Any portal user can view and edit the version.
2. VersionAccess.Protected - Any portal user can view, but only the version owner, feature layer owner, and portal administrator can edit the version.
3. VersionAccess.Private - Only the version owner, feature layer owner, and portal administrator can view and edit the version.

## Tags

branch versioning, edit, version control, version management server
