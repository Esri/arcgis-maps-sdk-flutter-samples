# Show portal user info

Retrieve a user's details via a Portal.

![Image of show portal user info](show_portal_user_info.png)

## Use case

This portal information can be used to provide a customized UI experience for the user. For example, you can show a thumbnail next to their username in the header of an application to indicate that they are currently logged in. Additionally, apps such as Collector and Explorer use this functionality to integrate with Portal.

## How to use the sample

When prompted, enter your ArcGIS Online credentials.

## How it works

1. A `Portal` is created, and supplied an `OAuthUserCredential` which uses OAuth in user mode.
2. When the app launches, the portal is loaded, which triggers an authentication challenge.
3. An `AuthenticationView` listens to the challenge and displays a login screen to allow user credentials to be entered.

If the portal is successfully loaded, the `portalUser` property is used to populate a series of fields including:

* fullName
* username
* email
* description
* access

Similarly, the `portalInfo` property is used to populate:

* organizationName
* organizationDescription
* thumbnailUrl
* canSearchPublic
* canSharePublic

## Relevant API

* AuthenticationManager
* AuthenticationView
* OAuthUserCredential
* ArcGISAuthenticationChallengeHandler
* PortalInfo
* PortalUser

## About the data

This sample signs into your ArcGIS Online account and displays the user's profile information.

## Tags

account, avatar, bio, cloud and portal, email, login, picture, profile, user, username
