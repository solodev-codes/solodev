# MASTER BUILD PROMPT

## Solodev — Futuristic Cross-Platform Developer & AI Design Portfolio

You are acting as a **senior Flutter architect, Firebase architect, UI/UX designer, security engineer, DevOps engineer, and product designer**.

I want you to build a production-quality personal portfolio platform called **Solodev**.

This is NOT a basic static portfolio website.

It must be a **modern, futuristic, highly polished, database-driven personal portfolio and professional showcase platform** that works across:

* Android
* iOS
* Web

The application must be built with:

* Flutter
* Dart
* Firebase
* VS Code
* Cline
* Riverpod for state management
* GoRouter for navigation
* Firebase Authentication
* Cloud Firestore
* Firebase Storage
* Firebase Cloud Functions
* Firebase Cloud Messaging
* Firebase App Check
* Responsive Flutter Web UI

The final product should feel like a premium technology product rather than a conventional developer portfolio.

---

# 1. CORE PRODUCT VISION

The application should present me as a professional:

* Flutter mobile application developer
* Firebase application developer
* AI designer
* UI/UX designer
* Graphic/flyer designer
* Web developer
* Technology creator
* Digital product developer

The portfolio should allow visitors to:

* Discover who I am
* Understand my skills
* Explore the services I offer
* View my projects
* Watch project videos
* View project screenshots
* View recent work
* View certificates
* View achievements
* Contact me
* Request a service
* Explore individual service categories
* See my latest work
* See featured projects
* Understand my development process
* View my professional journey
* Interact with the portfolio

I should be able to manage almost all portfolio content from a private admin dashboard without changing Flutter source code.

---

# 2. BRAND IDENTITY

Use a professional futuristic technology identity.

Primary brand color:

#1565C0

Use blue as the primary brand color.

Supporting colors should include:

* Deep navy
* Dark charcoal
* White
* Soft gray
* Subtle blue gradients
* Very limited cyan accents where appropriate

Do NOT make the application look childish, overly colorful, or like a generic template.

Design direction:

* Futuristic
* Minimal
* Premium
* Professional
* Clean
* High-tech
* Elegant
* Smooth
* Spacious
* Strong typography
* Excellent visual hierarchy
* Subtle animations
* Glassmorphism used carefully
* Soft gradients
* Modern cards
* Beautiful dark mode
* Professional light mode

The design must work equally well on:

* Mobile
* Tablet
* Desktop
* Large desktop monitors

Do not simply stretch the mobile interface onto desktop.

Create genuinely responsive layouts.

---

# 3. IMPORTANT DEVELOPMENT PRINCIPLE

DO NOT attempt to generate the entire application in one uncontrolled implementation.

Build the project in logical phases.

Before writing large amounts of code:

1. Inspect the existing project.
2. Create a proper architecture.
3. Create the folder structure.
4. Configure dependencies.
5. Configure Firebase.
6. Create models.
7. Create repositories/services.
8. Create authentication.
9. Create the public experience.
10. Create the admin system.
11. Add media management.
12. Add notifications.
13. Add security.
14. Add animations.
15. Test every major feature.
16. Fix compilation errors.
17. Fix runtime issues.
18. Perform a final architecture and security audit.

Do not silently make major architectural decisions.

If a decision affects security, database structure, scalability, or cross-platform compatibility, explain the decision briefly before implementing it.

---

# 4. PROJECT ARCHITECTURE

Use a scalable feature-first architecture.

Recommended structure:

lib/
core/
constants/
theme/
routing/
utils/
extensions/
errors/
responsive/
animations/
widgets/
services/

features/
home/
about/
services/
projects/
certificates/
achievements/
contact/
testimonials/
experience/
skills/
admin/
notifications/
settings/

data/
models/
repositories/
datasources/

firebase/
firebase_options.dart

main.dart

Use clear separation between:

* UI
* State management
* Business logic
* Repositories
* Firebase services
* Models

Avoid putting Firebase queries directly inside widgets.

---

# 5. STATE MANAGEMENT

Use Riverpod.

Prefer:

* Notifiers
* AsyncNotifiers where appropriate
* Providers
* Repository providers
* Stream providers for realtime Firestore data

Do not use unnecessary global mutable state.

Keep widgets as presentation-focused as possible.

---

# 6. NAVIGATION

Use GoRouter.

Create a centralized route configuration.

Public routes should include:

/
/home
/about
/services
/services/:serviceId
/projects
/projects/:projectId
/certificates
/achievements
/experience
/contact
/settings

Admin routes should be separated from public routes.

Example:

/admin/login
/admin
/admin/projects
/admin/services
/admin/certificates
/admin/achievements
/admin/messages
/admin/notifications
/admin/settings
/admin/profile
/admin/media

IMPORTANT:

Do not rely on a "secret URL" as security.

The admin area must be protected by Firebase Authentication and authorization.

The admin route can be unobvious/private from the public UI, but actual security must come from Firebase Auth + custom claims/security rules.

---

# 7. AUTHENTICATION

Use Firebase Authentication.

Admin authentication should support:

* Email/password
* Optional Google authentication if useful

Only authorized admin users can access the dashboard.

Implement an authorization mechanism using Firebase custom claims or a secure admin-role document.

Example:

role = admin

The client must NEVER be trusted to decide whether someone is an administrator.

Firebase Security Rules must enforce authorization.

Visitors do NOT need accounts just to browse the portfolio.

---

# 8. ADMIN DASHBOARD

Create a beautiful private admin dashboard.

Dashboard should display:

* Total projects
* Published projects
* Draft projects
* Services
* Certificates
* Achievements
* Contact messages
* Unread messages
* Views
* Popular projects
* Recent activity
* Recent uploads
* Notifications
* Storage usage indicators where practical

Create a clean dashboard with:

* Sidebar navigation on desktop
* Drawer navigation on mobile
* Top navigation
* Profile/admin menu
* Notification center
* Search
* Quick actions

Quick actions:

* Add Project
* Add Service
* Add Certificate
* Add Achievement
* Upload Media
* View Messages
* Send Notification

---

# 9. CONTENT MANAGEMENT SYSTEM

The admin should be able to manage portfolio content without editing code.

CRUD operations should exist for:

* Projects
* Services
* Certificates
* Achievements
* Experience
* Skills
* Testimonials
* Social links
* Contact information
* About section
* Homepage sections

Every content type should support appropriate:

* Create
* Read
* Update
* Delete
* Publish/unpublish
* Draft state

Add confirmation dialogs before destructive actions.

Use soft delete where appropriate.

---

# 10. SERVICES SYSTEM

Services are one of the most important parts of the portfolio.

Examples:

1. Flutter App Development
2. Firebase Development
3. AI Design
4. UI/UX Design
5. Flyer Design
6. Web Development
7. Mobile App UI Design
8. AI-Powered Product Design
9. Custom Digital Solutions

Each service should have:

* Title
* Short description
* Full description
* Icon
* Cover image
* Gallery
* Optional video
* Technologies
* Features
* Process
* Benefits
* Recent works
* Related projects
* Pricing information if I choose to add it
* Availability status
* Call-to-action
* Created date
* Updated date
* Sort order
* Published state

---

# 11. SERVICE DETAIL SCREEN

When a visitor opens a service, create a premium detailed page.

For example:

Flutter App Development

Sections:

* Hero section
* What I offer
* Technologies
* Development capabilities
* Development process
* Recent Flutter projects
* Screenshots
* Videos
* Key features
* Why work with me
* Frequently asked questions
* Call-to-action

The page should dynamically load data from Firestore.

Do NOT hard-code project listings.

---

# 12. PROJECT SYSTEM

Each project should support:

* Project name
* Short description
* Full description
* Category
* Technologies
* Platform
* Cover image
* Multiple images
* Optional videos
* Project URL
* App Store URL
* Play Store URL
* GitHub URL
* Website URL
* Client/project type
* Features
* Challenges
* Solution
* Results
* Development duration
* Featured status
* Published status
* Created date
* Updated date

Platforms:

* Android
* iOS
* Web
* Cross-platform

Categories can include:

* Flutter
* Firebase
* AI
* UI/UX
* Graphic Design
* Web
* Other

---

# 13. PROJECT DETAIL EXPERIENCE

Create a premium project showcase screen.

Hero:

* Project image/video
* Project title
* Category
* Technology badges
* Platform badges

Then:

* Overview
* Problem
* Solution
* Features
* Technologies
* Screenshots
* Video demonstration
* Development process
* Challenges
* Results
* Related services
* Related projects
* CTA

Images should open in a beautiful fullscreen viewer.

Videos should have a modern custom video player.

---

# 14. MEDIA SYSTEM

Firebase Storage will store:

* Images
* Videos
* Certificates
* Project assets
* Profile assets

Create a reusable media management system.

Every uploaded media item should have:

* Storage path
* Download URL
* File type
* File size
* Thumbnail if applicable
* Width
* Height
* Duration for video
* Created date
* Associated project/service/document
* Uploaded by

---

# 15. MEDIA COMPRESSION

THIS IS VERY IMPORTANT.

Never blindly upload huge media files.

Before uploading:

## Images

Compress images before Firebase Storage upload.

Support:

* JPEG
* PNG
* WebP where appropriate

Implement:

* Resize
* Quality compression
* Maximum dimensions
* Thumbnail generation

Example:

Large image:
10 MB

Upload version:
approximately 300 KB – 1.5 MB depending on image dimensions and quality.

Do not destroy visual quality unnecessarily.

---

# 16. VIDEO COMPRESSION

Videos must be compressed before upload where technically possible.

Target:

* Reasonable resolution
* Reasonable bitrate
* MP4/H.264 where practical
* Reduced file size
* Preserve acceptable visual quality

IMPORTANT:

Flutter mobile and Flutter Web have different capabilities.

Do not assume native video compression APIs work identically on Web.

Design the media pipeline according to platform capabilities.

If client-side video compression is unreliable on Web, implement a safe fallback and/or server-side processing architecture rather than breaking uploads.

For large videos, consider:

* Cloud Functions
* Cloud Run
* FFmpeg-based processing
* Thumbnail generation
* Multiple video resolutions

Do not upload enormous raw videos unnecessarily.

---

# 17. UPLOAD EXPERIENCE

When uploading:

Show:

* File picker
* Selected file
* Preview
* Original size
* Estimated compressed size
* Compression progress where supported
* Upload progress
* Upload percentage
* Success state
* Error state
* Cancel action

Never freeze the UI during compression or upload.

Handle:

* Slow internet
* Upload cancellation
* Network failure
* Unsupported file
* File too large
* Firebase permission failure

---

# 18. CERTIFICATE SYSTEM

Admin can upload certificates.

Each certificate:

* Certificate name
* Issuing organization
* Description
* Certificate image/PDF
* Date
* Credential ID if applicable
* Credential URL
* Skills associated
* Featured status
* Published status

Public certificate page should have a beautiful certificate gallery.

Clicking a certificate should open:

* Full image/PDF viewer
* Details
* Issuer
* Date
* Credential link

---

# 19. ACHIEVEMENT SYSTEM

Admin can add achievements.

Fields:

* Title
* Description
* Date
* Category
* Image
* Video
* External link
* Featured status

Create a visually impressive achievement timeline.

---

# 20. EXPERIENCE SYSTEM

Create a professional experience timeline.

Each experience:

* Organization/client
* Position
* Start date
* End date
* Description
* Responsibilities
* Technologies
* Images
* Projects
* Current position flag

The public page should display this as a modern timeline.

---

# 21. SKILLS SYSTEM

Create a dynamic skills section.

Skills should have:

* Name
* Category
* Icon/logo
* Proficiency representation if desired
* Years of experience if appropriate
* Featured state
* Sort order

Categories:

* Mobile Development
* Backend
* Firebase
* AI
* Design
* Web
* Tools
* Other

Avoid misleading percentage-based skill bars unless there is a meaningful reason to use them.

---

# 22. HOMEPAGE

The homepage should be visually outstanding.

Hero section:

"Flutter Developer & AI Designer"

with a dynamic professional subtitle.

Example concept:

"Building modern mobile, web and AI-powered digital experiences."

Do not overuse text.

Hero should contain:

* Professional profile image/avatar
* Subtle animated background
* Floating technology elements
* CTA buttons
* View My Work
* Contact Me

Possible animated elements:

* Flutter
* Firebase
* Dart
* AI
* UI/UX
* Mobile
* Web

Animations must remain subtle and professional.

---

# 23. HOMEPAGE SECTIONS

Suggested sections:

1. Hero
2. About Me
3. What I Do
4. Featured Services
5. Featured Projects
6. Technologies
7. Recent Work
8. Certificates
9. Achievements
10. Experience
11. Testimonials
12. Development Process
13. Contact
14. Footer

Admin should be able to control visibility and ordering where practical.

---

# 24. ABOUT SECTION

Include:

* Professional introduction
* Development philosophy
* Areas of expertise
* Career journey
* Technologies
* Personal brand

Do not fabricate achievements, clients, companies, years of experience, or statistics.

Everything should be editable from the admin panel.

---

# 25. CONTACT SYSTEM

Visitors should be able to send a message.

Fields:

* Name
* Email
* Phone optional
* Service interested in
* Subject
* Message

Store messages in Firestore.

Admin dashboard should show:

* Inbox
* Read/unread
* Timestamp
* Sender information
* Service
* Message status

Statuses:

* New
* Read
* In progress
* Replied
* Closed

---

# 26. ADMIN NOTIFICATIONS

I want to receive notifications when important events happen.

Examples:

* New contact message
* New service request
* New portfolio interaction
* Important admin events

Use:

Firebase Cloud Messaging.

Admin devices should register for notifications.

Implement:

* Device token storage
* Token refresh
* Notification permissions
* Notification handling
* Foreground notifications
* Background notifications
* Notification history

Use Cloud Functions to trigger important server-side notifications where appropriate.

Never expose Firebase server credentials inside the Flutter application.

---

# 27. VISITOR INTERACTION

Add useful interactive features.

Possible features:

* Project views
* Service views
* Favorite projects
* Share project
* Copy project link
* Social sharing
* Contact CTA
* Search
* Filters
* Recently viewed projects

For favorites, visitors can optionally use local storage without requiring an account.

Do not force visitors to create accounts just to browse.

---

# 28. SEARCH

Implement a professional search interface.

Search:

* Projects
* Services
* Skills
* Certificates
* Achievements

Search results should be grouped by content type.

Example:

Search "Firebase"

Results:

Services
Projects
Skills
Certificates

---

# 29. PROJECT FILTERING

Projects should be filterable by:

* Category
* Technology
* Platform
* Featured
* Recent

Add smooth animations when filtering.

---

# 30. ANALYTICS

Implement privacy-conscious analytics.

Track useful portfolio metrics such as:

* Page views
* Project views
* Service views
* Contact submissions
* Popular projects
* Popular services
* Device/platform
* Referrer where appropriate

Do not collect unnecessary personal information.

If Firebase Analytics is used, structure analytics events clearly.

Examples:

portfolio_project_view
portfolio_service_view
portfolio_contact_submit
portfolio_certificate_view
portfolio_project_share

---

# 31. PERFORMANCE

Performance is extremely important.

The application must:

* Lazy-load images
* Use thumbnails
* Avoid loading every project at startup
* Paginate large lists
* Use Firestore queries efficiently
* Cache where appropriate
* Avoid unnecessary rebuilds
* Use const widgets where appropriate
* Optimize animations
* Dispose controllers correctly
* Avoid memory leaks
* Avoid loading full-resolution videos unnecessarily

For Web:

* Optimize initial load
* Lazy-load sections
* Optimize images
* Avoid excessive JavaScript/WASM payloads
* Ensure good Lighthouse-style performance practices

---

# 32. RESPONSIVE DESIGN

Create responsive breakpoints.

Example:

Mobile:
< 600px

Tablet:
600px – 1024px

Desktop:
1024px+

Large desktop:
1440px+

Navigation should change appropriately.

Mobile:

* Bottom navigation or compact navigation
* Drawer where appropriate

Desktop:

* Sidebar or top navigation

Do not simply scale every element.

Use adaptive layouts.

---

# 33. DARK MODE

Implement:

* Light mode
* Dark mode
* System mode

Store user preference locally.

Dark mode should be genuinely designed, not just inverted colors.

---

# 34. ANIMATIONS

Use tasteful animations:

* Hero entrance
* Scroll reveal
* Card hover
* Page transitions
* Button interactions
* Loading skeletons
* Image transitions
* Project filtering
* Admin dashboard interactions

Do not over-animate.

The application should feel premium rather than like a gaming website.

---

# 35. LOADING STATES

Every asynchronous operation must have proper UI states.

Implement:

* Skeleton loading
* Empty state
* Error state
* Retry
* Upload progress
* Success state

Never show a blank screen while waiting for Firebase.

---

# 36. ERROR HANDLING

Create centralized error handling.

Handle:

* Firebase unavailable
* Permission denied
* Authentication failure
* Network failure
* Storage upload failure
* Firestore failure
* Invalid file
* Unsupported media
* Timeout
* Cloud Function failure

User-facing error messages should be understandable.

Developer logs should contain useful technical information without exposing sensitive information.

---

# 37. FIRESTORE DATA MODEL

Design normalized and scalable collections.

Possible structure:

users/{userId}

admins/{adminId}

services/{serviceId}

projects/{projectId}

certificates/{certificateId}

achievements/{achievementId}

experiences/{experienceId}

skills/{skillId}

testimonials/{testimonialId}

messages/{messageId}

notifications/{notificationId}

media/{mediaId}

analytics/{documentId}

settings/{documentId}

portfolio_sections/{sectionId}

Use timestamps:

createdAt
updatedAt

Use Firestore server timestamps wherever appropriate.

Do not use client-generated timestamps when server timestamps are more appropriate.

---

# 38. FIREBASE STORAGE STRUCTURE

Use an organized storage structure.

Example:

portfolio/
profile/
projects/
{projectId}/
cover/
images/
videos/
thumbnails/
services/
{serviceId}/
cover/
images/
videos/
certificates/
achievements/
experience/
general/

Do not put every file into one flat directory.

---

# 39. FIREBASE SECURITY

Security is critical.

Create strict Firestore Security Rules.

Public visitors:

READ:
Only published public content.

WRITE:
No direct public writes to portfolio content.

Contact submissions:
Allow controlled creation with validation.

Admin:

READ/WRITE:
Only authorized admin.

Storage:

Public:
Only files intended to be publicly accessible.

Admin:
Upload/write/delete only for authorized admins.

Validate:

* File type
* File size
* Storage path
* Ownership
* Admin authorization

Do not trust values sent by the client.

---

# 40. ADMIN SECURITY

The admin dashboard must NOT be protected simply by hiding a button.

Implement:

Firebase Authentication

*

Admin authorization

*

Firestore Security Rules

*

Storage Security Rules

*

App Check where supported

*

Secure Cloud Functions

The application must remain secure even if someone discovers:

/admin/login

---

# 41. FIREBASE APP CHECK

Configure Firebase App Check where supported.

Use platform-appropriate providers.

Do not break development environments while configuring App Check.

Clearly separate development and production configurations.

---

# 42. ENVIRONMENT CONFIGURATION

Do not hard-code secrets.

Use proper configuration management.

Never place:

* Private API keys
* Server credentials
* Service account JSON
* Admin secrets

inside the Flutter client.

Remember:

Firebase client configuration values are not equivalent to server secrets, but Security Rules must still protect the backend.

---

# 43. CLOUD FUNCTIONS

Use Firebase Cloud Functions for server-side operations such as:

* Admin notifications
* Contact notification triggers
* Media processing where required
* Cleanup of deleted media
* Server-side analytics aggregation
* Admin operations requiring trusted execution
* Notification dispatch
* Other privileged operations

Use TypeScript for Cloud Functions.

---

# 44. SEO FOR FLUTTER WEB

Since the portfolio is also a web portfolio, optimize the web experience for discoverability.

Implement where compatible with Flutter Web:

* Page titles
* Meta descriptions
* Open Graph metadata
* Social preview metadata
* Favicon
* Semantic content where possible
* Clean URLs
* Shareable project URLs

Create meaningful page titles such as:

"Flutter App Development | Solodev"

"Nestadeck — Solodev Project"

"AI Design Services | Solodev"

Do not generate fake SEO content.

---

# 45. ACCESSIBILITY

Follow accessibility best practices.

Support:

* Good contrast
* Text scaling
* Semantic labels
* Keyboard navigation on Web
* Screen-reader-friendly controls
* Focus states
* Large enough touch targets

Do not communicate information using color alone.

---

# 46. INTERNATIONALIZATION

Architect the application so localization can be added later.

Do not hard-code every user-facing string directly inside widgets.

Initially support English.

Structure translations so other languages can be added later.

---

# 47. ADMIN MEDIA LIBRARY

Create a media library.

Admin can:

* Browse uploaded media
* Search media
* Filter by type
* Preview media
* Copy media URL where appropriate
* See file size
* See upload date
* Delete unused media
* See where media is being used

Prevent deleting media that is actively referenced unless the admin confirms.

---

# 48. DRAFT/PUBLISH SYSTEM

Content should support:

Draft

Published

Archived

This allows me to prepare projects before making them public.

Example:

I upload a new project today.

Status:

Draft

I can preview it.

Then press:

Publish

It becomes visible to visitors.

---

# 49. PREVIEW MODE

Admin should be able to preview draft content as visitors would see it.

Create:

"Preview"

button.

Preview should not require publishing.

---

# 50. FEATURED CONTENT

Allow admin to mark content as:

Featured

The homepage should dynamically display featured projects/services.

Do not hard-code which project is featured.

---

# 51. PORTFOLIO HOME CUSTOMIZATION

Create a settings system where I can control:

* Hero title
* Hero subtitle
* About text
* CTA text
* Social links
* Contact information
* Profile image
* Homepage sections
* Featured projects
* Featured services

This should be stored in Firestore.

---

# 52. SOCIAL LINKS

Support:

* GitHub
* LinkedIn
* Facebook
* Instagram
* X
* YouTube
* WhatsApp
* Portfolio/website

Admin can edit links.

Only display links that are configured.

---

# 53. WHATSAPP CONTACT

Where appropriate, provide a WhatsApp CTA.

Construct the URL safely from configured contact information.

Do not hard-code the phone number.

---

# 54. PROFESSIONAL PROFILE

Create a polished profile page containing:

* Profile image
* Name
* Professional title
* Short biography
* Skills
* Services
* Certificates
* Achievements
* Experience
* Projects
* Contact CTA

---

# 55. FUTURISTIC UI DETAILS

Use visual details such as:

* Subtle glowing borders
* Soft blue gradients
* Frosted glass panels
* Modern cards
* Thin separators
* Floating elements
* Gradient typography used sparingly
* Animated background particles only if performance allows
* Interactive hover effects on desktop
* Smooth transitions
* Premium icons

Do not make the entire interface glow.

Use futuristic elements as accents.

---

# 56. PROJECT CARD DESIGN

Project cards should display:

* Image/video thumbnail
* Project title
* Short description
* Technology chips
* Platform
* Category
* Featured indicator where appropriate
* View Project button

Desktop cards can have subtle hover animations.

Mobile cards should remain easy to use.

---

# 57. SERVICE CARD DESIGN

Service cards should show:

* Icon
* Service title
* Short description
* Technologies
* Learn More button

Include subtle hover animation on Web.

---

# 58. CONTACT FORM SECURITY

Protect the contact form against abuse.

Implement:

* Input validation
* Rate limiting where practical
* App Check
* Spam protection strategy
* Maximum message length
* Email validation
* Sanitization

Do not allow arbitrary Firestore writes.

---

# 59. ADMIN MESSAGE SYSTEM

Create an inbox similar to a lightweight professional CRM.

Features:

* Inbox
* Search
* Filter
* Read/unread
* Status
* Notes
* Message details
* Timestamp
* Sender
* Service requested

Allow admin to mark:

New
Read
In Progress
Replied
Closed

---

# 60. NOTIFICATION CENTER

Admin notification page should show:

* Notification title
* Message
* Type
* Time
* Read status

Examples:

"New contact message"

"New service inquiry"

"Project published"

"Upload completed"

---

# 61. OFFLINE HANDLING

Where possible, provide graceful offline behavior.

Firestore offline caching can be used where appropriate.

If the user loses connection:

Show:

"You appear to be offline."

Do not crash.

---

# 62. FIREBASE COST AWARENESS

Design the architecture to avoid unnecessary Firebase costs.

Avoid:

* Excessive realtime listeners
* Repeated Firestore reads
* Loading large media unnecessarily
* Duplicate downloads
* Huge unoptimized images
* Unnecessary Cloud Function invocations

Use:

* Pagination
* Caching
* Lazy loading
* Optimized queries
* Thumbnails

---

# 63. DATA VALIDATION

Every model should have validation.

Examples:

Project:

* Title required
* Description required
* Category required

Service:

* Name required
* Description required

Certificate:

* Title required
* Issuer required

Contact:

* Name required
* Email required
* Message required

Do not allow invalid data into Firestore.

---

# 64. UI COMPONENT LIBRARY

Create reusable components.

Examples:

AppButton
AppTextField
GlassCard
SectionHeader
ProjectCard
ServiceCard
CertificateCard
AchievementCard
SkillChip
ResponsiveContainer
LoadingSkeleton
ErrorView
EmptyState
MediaPicker
ImageViewer
VideoPlayer
AdminSidebar
AdminTopBar
StatCard
NotificationTile

Avoid duplicating UI code.

---

# 65. THEMING

Create centralized theme configuration.

Use:

ThemeData

ColorScheme

TextTheme

Custom component themes.

Support:

lightTheme

darkTheme

Do not scatter colors throughout the application.

The primary brand blue must come from centralized theme constants.

---

# 66. TYPOGRAPHY

Use a modern professional font.

Select a highly readable modern font such as:

Inter

or another suitable Google Font.

Typography hierarchy must be obvious.

Avoid excessive font sizes.

---

# 67. ICONS

Use Material Symbols or another professional icon system.

Avoid random icon styles.

Maintain visual consistency.

---

# 68. SECURITY RULE TESTING

Create Firebase emulator tests where practical.

Test:

* Anonymous public reads
* Published content reads
* Draft content protection
* Admin reads
* Admin writes
* Unauthorized writes
* Contact submissions
* Storage uploads
* Unauthorized storage deletion

Security must be tested, not assumed.

---

# 69. TESTING

Create tests for:

* Models
* Repositories
* Validators
* Providers
* Important widgets
* Authentication
* Admin authorization
* Firestore interactions where practical

Perform:

flutter analyze

flutter test

and appropriate platform builds.

Fix all errors.

Do not ignore warnings that indicate actual architectural problems.

---

# 70. PLATFORM TESTING

Verify:

Android
iOS
Web

Where the environment permits.

For iOS-specific functionality, ensure the project structure and dependencies are compatible even if the current development machine cannot perform a final iOS build.

---

# 71. WEB DEPLOYMENT

Prepare for Firebase Hosting.

The final web application should be deployable using Firebase Hosting.

Create appropriate:

firebase.json

and hosting configuration.

Ensure Flutter Web routing works with refresh/deep links.

---

# 72. ANDROID BUILD

Prepare:

* Debug
* Release

Ensure package/application ID is configurable and documented.

Do not make arbitrary package-name changes if an existing project already has one.

---

# 73. IOS BUILD

Prepare iOS configuration correctly.

Do not add unsupported plugins that break iOS.

Ensure permissions are correctly configured for:

* Photos
* Camera if needed
* Notifications
* Media access

Only request permissions that are actually required.

---

# 74. PRIVACY

Create a privacy-conscious architecture.

Do not collect personal visitor information unnecessarily.

If analytics or contact data is collected, structure the privacy policy accordingly.

Create placeholders for:

* Privacy Policy
* Terms of Service
* Cookie/analytics notice if required

---

# 75. ADMIN AUDIT LOG

Create an optional admin audit log.

Record important actions such as:

* Project created
* Project updated
* Project published
* Project deleted
* Certificate added
* Achievement added
* Media deleted
* Settings changed

Each event should record:

* Admin ID
* Action
* Target
* Timestamp

Do not store unnecessary sensitive information.

---

# 76. BACKUP/RECOVERY CONSIDERATIONS

Structure Firestore and Storage data so it can be backed up.

Document:

* Firestore collections
* Storage paths
* Firebase configuration
* Cloud Functions
* Security Rules

Do not build destructive operations without confirmation.

---

# 77. ADMIN SETTINGS

Create an admin settings page.

Settings:

* Profile
* Branding
* Social links
* Contact
* Homepage
* Notifications
* Analytics preferences
* Theme preferences
* Portfolio settings

---

# 78. PUBLIC FOOTER

Footer should contain:

* Solodev branding
* Short description
* Navigation
* Services
* Social links
* Contact
* Copyright
* Privacy
* Terms

Do not clutter the footer.

---

# 79. MICROCOPY

Use professional copy.

Avoid generic phrases such as:

"Welcome to my amazing portfolio!!!"

Use confident but realistic language.

Never fabricate:

* Client numbers
* Revenue
* Awards
* Certifications
* Experience
* Project results

Only display facts entered by the admin.

---

# 80. EMPTY STATES

Create beautiful empty states.

Examples:

"No projects published yet."

"No certificates added yet."

"No achievements available."

"No messages yet."

Do not show broken-looking screens.

---

# 81. SECURITY PRINCIPLE

Assume the client can be inspected.

Never trust Flutter UI to protect data.

Firebase Rules are the final enforcement layer.

The application should remain secure even if someone:

* Reverse engineers the app
* Finds admin routes
* Calls Firebase directly
* Inspects network requests
* Manipulates the client

---

# 82. CODE QUALITY

Write production-quality Dart.

Follow:

* SOLID principles
* DRY
* Separation of concerns
* Repository pattern
* Dependency injection where useful
* Strong typing
* Null safety
* Meaningful names
* Small reusable widgets

Avoid:

* Massive widgets
* God classes
* Repeated Firebase queries
* Hard-coded UI content
* Hard-coded credentials
* Magic numbers
* Unnecessary packages

---

# 83. PACKAGE MANAGEMENT

Before adding a package:

1. Check whether Flutter/Dart/Firebase already provides the functionality.
2. Prefer well-maintained packages.
3. Ensure Android/iOS/Web compatibility.
4. Avoid abandoned packages.
5. Avoid packages that create unnecessary platform-specific problems.

Do not add dependencies simply because they are convenient.

---

# 84. DEVELOPMENT WORKFLOW FOR CLINE

Follow this workflow strictly.

PHASE 1:
Inspect repository.

PHASE 2:
Create architecture.

PHASE 3:
Configure Flutter and dependencies.

PHASE 4:
Configure Firebase.

PHASE 5:
Create models and repositories.

PHASE 6:
Create theme/design system.

PHASE 7:
Build public homepage.

PHASE 8:
Build services/projects/certificates/achievements.

PHASE 9:
Build contact system.

PHASE 10:
Build authentication.

PHASE 11:
Build admin dashboard.

PHASE 12:
Build media upload/compression.

PHASE 13:
Build notifications.

PHASE 14:
Implement Firebase Security Rules.

PHASE 15:
Implement analytics.

PHASE 16:
Implement responsive Web experience.

PHASE 17:
Testing.

PHASE 18:
Performance optimization.

PHASE 19:
Security audit.

PHASE 20:
Final cleanup.

After every major phase:

* Run flutter analyze
* Fix errors
* Check imports
* Check navigation
* Check responsive behavior
* Check Firebase calls
* Check security implications

Do not continue while the project is left in a clearly broken compilation state.

---

# 85. IMPORTANT: DO NOT DESTROY EXISTING WORK

If this is being implemented inside an existing Flutter repository:

FIRST inspect:

* pubspec.yaml
* lib/
* android/
* ios/
* web/
* firebase configuration
* existing assets
* existing routing
* existing Firebase initialization

Do not delete existing functionality without understanding it.

If the repository is empty, create the project structure cleanly.

---

# 86. DESIGN-FIRST REQUIREMENT

Before implementing complex screens, create the visual system.

Define:

* Color palette
* Typography
* Spacing
* Border radius
* Shadows
* Cards
* Buttons
* Inputs
* Navigation
* Responsive containers
* Animations

Then use the design system everywhere.

The application must look like ONE product.

---

# 87. NO GENERIC TEMPLATE DESIGN

Do not produce a generic "developer portfolio template."

The design should feel custom-built for Solodev.

It should communicate:

Flutter
Firebase
AI
Design
Technology
Professionalism
Creativity
Modern software engineering

The first impression should feel like a premium technology product.

---

# 88. FUTURE EXTENSIBILITY

Architect the system so additional features can be added later:

* Blog
* Case studies
* Client portal
* Service booking
* Invoicing
* Payment integration
* Resume download
* Newsletter
* Job request system
* AI portfolio assistant
* Visitor chat
* Project collaboration
* Admin roles
* Multiple administrators
* Client testimonials
* Digital products

Do not implement these unless required, but do not create an architecture that makes future expansion unnecessarily difficult.

---

# 89. OPTIONAL AI PORTFOLIO ASSISTANT

Architect for a future AI assistant.

The assistant could eventually answer:

"What services does Solodev offer?"

"Show me Flutter projects."

"Does Solodev build Firebase apps?"

"How can I contact Solodev?"

"Show me recent AI design work."

Do NOT expose private admin information to an AI assistant.

If implemented later, use a secure backend architecture.

---

# 90. FINAL QUALITY STANDARD

The final application must feel like something I could confidently show to:

* Clients
* Companies
* Recruiters
* Developers
* Business owners
* Potential collaborators

It must not feel like a student demo.

It must not feel like a basic CRUD Firebase project.

It must look and behave like a real professional product.

---

# 91. BEFORE DECLARING THE PROJECT COMPLETE

Perform a complete checklist.

## UI

* [ ] Mobile responsive
* [ ] Tablet responsive
* [ ] Desktop responsive
* [ ] Light mode
* [ ] Dark mode
* [ ] Animations
* [ ] Loading states
* [ ] Empty states
* [ ] Error states
* [ ] Accessibility

## Firebase

* [ ] Authentication
* [ ] Firestore
* [ ] Storage
* [ ] Cloud Functions
* [ ] FCM
* [ ] App Check
* [ ] Security Rules

## Admin

* [ ] Login
* [ ] Authorization
* [ ] Dashboard
* [ ] Projects
* [ ] Services
* [ ] Certificates
* [ ] Achievements
* [ ] Experience
* [ ] Skills
* [ ] Media
* [ ] Messages
* [ ] Notifications
* [ ] Settings

## Media

* [ ] Image compression
* [ ] Video compression strategy
* [ ] Thumbnails
* [ ] Upload progress
* [ ] Error handling
* [ ] File validation

## Public

* [ ] Homepage
* [ ] About
* [ ] Services
* [ ] Projects
* [ ] Certificates
* [ ] Achievements
* [ ] Experience
* [ ] Contact
* [ ] Search
* [ ] Filters
* [ ] Social sharing

## Code

* [ ] flutter analyze passes
* [ ] flutter test passes
* [ ] No obvious dead code
* [ ] No hard-coded secrets
* [ ] No insecure Firebase rules
* [ ] No unnecessary dependencies
* [ ] No major memory leaks
* [ ] No unnecessary Firestore listeners

---

# 92. MOST IMPORTANT INSTRUCTION

DO NOT rush.

Do not generate thousands of lines of code just to claim the application is complete.

Build carefully.

When something is uncertain, inspect the project and existing APIs before implementing it.

When a package has platform limitations, account for them.

When Firebase functionality requires backend security, implement it server-side.

When a feature cannot work identically on Android, iOS, and Web, design an appropriate cross-platform solution rather than pretending the APIs are identical.

Prioritize:

1. Correctness
2. Security
3. Maintainability
4. Performance
5. Responsive design
6. User experience
7. Visual quality
8. Extensibility

The goal is to create a **serious, production-quality, futuristic Solodev portfolio platform**, not merely a portfolio webpage.

Start by inspecting the repository and environment.

Then present the proposed architecture and implementation plan.

After that, implement the project phase by phase, validating each phase before moving to the next.
