import sys
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (KeepTogether, PageBreak, Paragraph, Preformatted,
                                SimpleDocTemplate, Spacer, Table, TableStyle)

FONT_DIR = '/usr/share/fonts/truetype/dejavu/'
pdfmetrics.registerFont(TTFont('Sans', FONT_DIR + 'DejaVuSans.ttf'))
pdfmetrics.registerFont(TTFont('Sans-Bold', FONT_DIR + 'DejaVuSans-Bold.ttf'))
pdfmetrics.registerFont(TTFont('Mono', FONT_DIR + 'DejaVuSansMono.ttf'))
pdfmetrics.registerFontFamily('Sans', normal='Sans', bold='Sans-Bold',
                              italic='Sans', boldItalic='Sans-Bold')

INK = colors.HexColor('#1f2933')
MUTED = colors.HexColor('#52606d')
ACCENT = colors.HexColor('#e8710a')
CODE_BG = colors.HexColor('#f4f5f7')
RULE = colors.HexColor('#d9dde3')

body = ParagraphStyle('body', fontName='Sans', fontSize=9.5, leading=14,
                      textColor=INK, spaceAfter=5, alignment=TA_LEFT)
small = ParagraphStyle('small', parent=body, fontSize=8.5, leading=12, textColor=MUTED)
h1 = ParagraphStyle('h1', parent=body, fontName='Sans-Bold', fontSize=15, leading=20,
                    spaceBefore=10, spaceAfter=8, textColor=INK, keepWithNext=1)
h2 = ParagraphStyle('h2', parent=body, fontName='Sans-Bold', fontSize=11.5, leading=16,
                    spaceBefore=8, spaceAfter=4, textColor=INK, keepWithNext=1)
title = ParagraphStyle('title', parent=body, fontName='Sans-Bold', fontSize=24,
                       leading=30, spaceAfter=6)
subtitle = ParagraphStyle('subtitle', parent=body, fontSize=12, leading=17, textColor=MUTED)
bullet = ParagraphStyle('bullet', parent=body, leftIndent=14, bulletIndent=4, spaceAfter=3)
code_style = ParagraphStyle('code', fontName='Mono', fontSize=8, leading=11, textColor=INK)
cell = ParagraphStyle('cell', parent=body, fontSize=8.5, leading=11.5, spaceAfter=0)
cell_b = ParagraphStyle('cellb', parent=cell, fontName='Sans-Bold')

story = []


def P(text, style=body):
    story.append(Paragraph(text, style))


def H1(text):
    story.append(Paragraph(text, h1))


def H2(text):
    story.append(Paragraph(text, h2))


def bullets(items):
    for item in items:
        story.append(Paragraph(item, bullet, bulletText='•'))


def steps(items):
    for i, item in enumerate(items, 1):
        story.append(Paragraph(item, bullet, bulletText=f'{i}.'))


def code(text):
    pre = Preformatted(text.strip('\n'), code_style)
    t = Table([[pre]], colWidths=[170 * mm])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), CODE_BG),
        ('BOX', (0, 0), (-1, -1), 0.5, RULE),
        ('LEFTPADDING', (0, 0), (-1, -1), 7), ('RIGHTPADDING', (0, 0), (-1, -1), 7),
        ('TOPPADDING', (0, 0), (-1, -1), 6), ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t)
    story.append(Spacer(1, 6))


def table(rows, widths):
    data = [[Paragraph(c, cell_b if r == 0 else cell) for c in row]
            for r, row in enumerate(rows)]
    t = Table(data, colWidths=[w * mm for w in widths], repeatRows=1)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), CODE_BG),
        ('LINEBELOW', (0, 0), (-1, -1), 0.4, RULE),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 5), ('RIGHTPADDING', (0, 0), (-1, -1), 5),
        ('TOPPADDING', (0, 0), (-1, -1), 4), ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(t)
    story.append(Spacer(1, 8))


def c(text):
    return f'<font name="Mono" size="8.5">{escape(text)}</font>'


# ---------------------------------------------------------------- cover
story.append(Spacer(1, 40 * mm))
P('fcm_push_kit', title)
P('Reusable Firebase push notifications for Flutter (Android and iOS)<br/>'
  'Proof of concept and integration guide', subtitle)
story.append(Spacer(1, 10 * mm))
table([
    ['Item', 'Value'],
    ['Package', c('packages/fcm_push_kit') + ' (version 0.1.0)'],
    ['Repository', 'github.com/Soumya8792/push_notification'],
    ['Demo app', c('push_notification_demo') + ' (same repository)'],
    ['Firebase project', c('push-notification-bfe0b') + ' (project number 845589201307)'],
    ['Platforms', 'Android 7.0+ (API 24), iOS 15.0+'],
    ['Stack', 'Flutter 3.47, firebase_core 5.1, firebase_messaging 17.0, '
              'flutter_local_notifications 22.3'],
    ['Date', '3 November 2026'],
], [40, 130])
story.append(PageBreak())

# ---------------------------------------------------------------- 1
H1('1. Purpose and scope')
P('Every app we build needs the same push notification plumbing: Firebase setup, permission '
  'prompts, device tokens, showing notifications while the app is open, and opening the right '
  'screen when a user taps one. This POC packages that plumbing once as <b>fcm_push_kit</b>, '
  'so a new project adds one dependency, does the native setup checklist, and calls one '
  'initialize method.')
P('The POC proves the following on both Android and iOS:')
bullets([
    'Notifications are received in all three app states: foreground, background and terminated.',
    'A tap opens the screen named in the payload (deep link), e.g. /details?id=42.',
    'Device tokens can be read and refreshed, and topics can be subscribed to.',
    'The same package can be consumed by several apps via a git dependency.',
])
P('Out of scope for the POC: a production backend that stores tokens, notification '
  'analytics, rich media (images), action buttons, and web/desktop targets.')

H1('2. Architecture')
P('The app talks only to fcm_push_kit. The package wraps the two Flutter plugins and hides '
  'the platform differences between Android and iOS.')
code('''
 Firebase console / your backend (FCM HTTP v1 API)
                 |
                 v
   Firebase Cloud Messaging  --(APNs on iOS)-->  device
                 |
 +----------------------- Flutter app -------------------------+
 |  main.dart / router                                         |
 |       |  initialize(), onNotificationTap, getToken()        |
 |       v                                                     |
 |  fcm_push_kit (shared package)                              |
 |     |- firebase_messaging           (FCM, tokens, taps)     |
 |     '- flutter_local_notifications  (Android foreground)    |
 +-------------------------------------------------------------+
''')
H2('Behaviour per app state')
table([
    ['App state', 'Android', 'iOS', 'Tap reaches the app via'],
    ['Foreground', 'Package shows a local notification on the high-importance channel',
     'System banner via foreground presentation options (no duplicate)',
     c('onNotificationTap') + ' (source: foreground / background)'],
    ['Background', 'System tray (FCM SDK)', 'System banner (APNs)',
     c('onNotificationTap') + ' (source: background)'],
    ['Terminated', 'System tray (FCM SDK)', 'System banner (APNs)',
     c('getInitialTap()') + ' after the first frame'],
], [24, 46, 46, 54])

H2('Repository layout')
code('''
push_notification_demo/
  lib/main.dart                 <- initializes FcmPushKit, handles initial tap
  lib/router/app_router.dart    <- go_router + tap listener + "Copy FCM Token"
  android/app/build.gradle.kts  <- core library desugaring
  ios/Runner/AppDelegate.swift  <- UNUserNotificationCenter delegate
  ios/Runner/Runner.entitlements<- aps-environment (Push Notifications)
  ios/Runner/Info.plist         <- UIBackgroundModes: remote-notification
  packages/fcm_push_kit/        <- the reusable package
    lib/src/fcm_push_kit.dart          FcmPushKit (main API)
    lib/src/fcm_push_kit_config.dart   FcmPushKitConfig
    lib/src/push_notification_tap.dart PushNotificationTap, TapSource
    test/                              unit tests
''')

# ---------------------------------------------------------------- 3
H1('3. Fixing the "Firebase CLI Login Failed" error')
P('<b>Symptom:</b> after choosing the Google account, the browser shows '
  '"Oops! Firebase CLI Login Failed" on localhost:9005.')
P('<b>Cause</b> (from firebase-debug.log): the browser step succeeded, but the CLI\'s '
  'follow-up request that exchanges the code for a token was cut off: '
  + c('FetchError: Invalid response body ... oauth2/token: Premature close') +
  '. This is a dropped network connection (VPN, proxy, firewall or unstable Wi-Fi), seen '
  'here with an outdated CLI (15.22.0) on Node 24.')
P('<b>Fix:</b>')
steps([
    'Update the CLI (already done on this machine, now 15.34.2): ' +
    c('npm install -g firebase-tools@latest'),
    'Start clean and log in again: ' + c('firebase logout') + ' then ' +
    c('firebase login --reauth') + '. Pick the Google account that owns the project '
    'in the console.',
    'If it still fails, disconnect VPN/proxy and retry, or use the copy-paste flow, which '
    'does not rely on localhost: ' + c('firebase login --no-localhost'),
    'Last resort: use Node 22 LTS: ' + c('nvm install 22 && nvm use 22 && npm i -g firebase-tools'),
    'Verify: ' + c('firebase projects:list') + ' must list ' + c('push-notification-bfe0b') + '.',
])

H1('4. Firebase project setup (once per app)')
P('The console currently shows <i>"There are no apps in your project"</i>. FlutterFire CLI '
  'registers the Android and iOS apps and writes the config files for you.')
steps([
    'Choose final app IDs first. The demo still uses ' + c('com.example.push_notification_demo') +
    ' (Android) and ' + c('com.example.pushNotificationDemo') + ' (iOS); change them to your '
    'own reverse-domain IDs before registering, because Firebase and APNs are tied to them.',
    'Install FlutterFire CLI: ' + c('dart pub global activate flutterfire_cli'),
    'From the app root run:',
])
code('''
flutterfire configure \\
  --project=push-notification-bfe0b \\
  --platforms=android,ios
''')
P('This creates ' + c('lib/firebase_options.dart') + ', ' +
  c('android/app/google-services.json') + ', ' + c('ios/Runner/GoogleService-Info.plist') +
  ' and adds the Google Services Gradle plugin. Re-run it whenever app IDs change.')

H1('5. Adding the package to a project')
H2('Inside this repository')
code('''
dependencies:
  firebase_core: ^5.1.0
  fcm_push_kit:
    path: packages/fcm_push_kit
''')
H2('From any other project (recommended for reuse)')
code('''
dependencies:
  firebase_core: ^5.1.0
  fcm_push_kit:
    git:
      url: https://github.com/Soumya8792/push_notification.git
      path: packages/fcm_push_kit
      ref: fcm_push_kit-v0.1.0   # tag; use main only while developing
''')
P('Pin a tag in production apps so a change to the package never reaches an app until '
  'that app bumps the ref. Then run ' + c('flutter pub get') + '.')

# ---------------------------------------------------------------- 6
H1('6. Android native setup')
P('All of the following is already applied in the demo app.')
H2('android/app/build.gradle.kts')
code('''
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true   // required by flutter_local_notifications
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        minSdk = flutter.minSdkVersion           // 24 in Flutter 3.47; 24 is required
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
''')
H2('android/app/src/main/AndroidManifest.xml')
code('''
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<application ...>
    <!-- must equal FcmPushKitConfig.androidChannelId -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="high_importance_channel" />
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@mipmap/ic_launcher" />
</application>
''')
P('Android 13+ asks the user for notification permission; the package triggers the prompt '
  'during initialize() unless ' + c('requestPermissionOnInit: false') + '. For production, '
  'add a white, transparent small icon (e.g. ' + c('@drawable/ic_notification') + ') and use '
  'it in both the manifest and the config.')

H1('7. iOS native setup')
H2('Apple Developer account and Firebase console (manual, once per app)')
steps([
    'developer.apple.com, then Certificates, IDs & Profiles, then Keys: create a key with '
    '<b>Apple Push Notifications service (APNs)</b> enabled and download the .p8 file '
    '(downloadable only once). Note the Key ID and your Team ID.',
    'Firebase console, then Project settings, then Cloud Messaging, then Apple app '
    'configuration: upload the .p8 with the Key ID and Team ID. One key works for all apps '
    'in the team, for both development and production.',
    'Make sure the App ID (bundle ID) has the Push Notifications capability.',
])
H2('Xcode project (already applied in the demo)')
bullets([
    '<b>Push Notifications</b> capability: ' + c('ios/Runner/Runner.entitlements') +
    ' with ' + c('aps-environment') + ', linked via ' + c('CODE_SIGN_ENTITLEMENTS') + '.',
    '<b>Background Modes</b>: ' + c('UIBackgroundModes') + ' = fetch, remote-notification '
    'in Info.plist.',
    'Open ' + c('ios/Runner.xcworkspace') + ' in Xcode, then Signing &amp; Capabilities: '
    'select your Team. The two capabilities above should be listed.',
])
H2('ios/Runner/AppDelegate.swift')
code('''
override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
  return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
''')
P('Test iOS push on a <b>real iPhone</b>; Simulator support for APNs is limited. The FCM '
  'token on iOS is only available after the APNs token arrives; '
  + c('getToken()') + ' waits up to 5 seconds for it.')

# ---------------------------------------------------------------- 8
H1('8. Using the package in Dart')
H2('Initialize in main()')
code('''
import 'package:fcm_push_kit/fcm_push_kit.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(RemoteMessage message) async {
  await fcmPushKitDefaultBackgroundHandler(message); // initializes Firebase
  // e.g. update a badge count or local cache. No UI work here.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FcmPushKit.instance.initialize(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    config: const FcmPushKitConfig(
      topics: ['all'],
      backgroundHandler: backgroundMessageHandler,
      enableLogs: true,
    ),
  );

  // Taps while the app is running (foreground or background).
  FcmPushKit.instance.onNotificationTap.listen((tap) {
    final location = tap.location;            // "/details?id=42"
    if (location != null) router.go(location);
  });

  // Keep the backend's copy of the token current.
  FcmPushKit.instance.onTokenRefresh.listen(api.saveDeviceToken);

  runApp(const MyApp());
}
''')
H2('Handle the tap that launched the app')
code('''
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final tap = await FcmPushKit.instance.getInitialTap();
    final location = tap?.location;
    if (location != null) router.go(location);
  });
}
''')
H2('Token, topics and logout')
code('''
final token = await FcmPushKit.instance.getToken();   // send to your backend
await FcmPushKit.instance.subscribeToTopic('offers');
await FcmPushKit.instance.unsubscribeFromTopic('offers');
await FcmPushKit.instance.deleteToken();              // on logout
''')

H1('9. API reference')
table([
    ['Member', 'Description'],
    [c('initialize({firebaseOptions, config})'), 'Initializes Firebase (if needed), FCM, the '
     'Android channel, listeners, permission and topics. Call once before runApp.'],
    [c('requestPermission()'), 'Shows the OS prompt; returns true when allowed (authorized or provisional).'],
    [c('getToken()'), 'Current FCM registration token, or null. On iOS waits for APNs first.'],
    [c('onTokenRefresh'), 'Stream of new tokens. Send each one to the backend.'],
    [c('deleteToken()'), 'Invalidates the token (logout).'],
    [c('subscribeToTopic / unsubscribeFromTopic'), 'Topic messaging, e.g. "all", "offers".'],
    [c('onNotificationTap'), 'Stream of PushNotificationTap for taps while the app runs.'],
    [c('getInitialTap()'), 'The tap that launched the app from terminated state; returns it once.'],
    [c('onForegroundMessage'), 'Stream of RemoteMessage received while the app is open.'],
    [c('register / onRegistered / unregister'), 'Firebase Installation ID (FID) registration '
     'introduced in firebase_messaging 17, for projects moving away from tokens.'],
    [c('isInitialized'), 'True after a successful initialize().'],
], [62, 108])
table([
    ['FcmPushKitConfig field', 'Default', 'Meaning'],
    [c('androidChannelId'), c('high_importance_channel'), 'Must match the manifest meta-data.'],
    [c('androidChannelName / Description'), 'High Importance Notifications', 'Shown in Android app settings.'],
    [c('androidSmallIcon'), c('@mipmap/ic_launcher'), 'Small icon for foreground notifications.'],
    [c('showForegroundNotifications'), 'true', 'Show banners while the app is open.'],
    [c('requestPermissionOnInit'), 'true', 'Set false to ask later (after onboarding).'],
    [c('routeKey'), c('route'), 'Data key holding the deep-link route.'],
    [c('topics'), '[]', 'Topics to subscribe to on start.'],
    [c('backgroundHandler'), 'built-in', 'Top-level function with @pragma(\'vm:entry-point\').'],
    [c('enableLogs'), 'false', 'Debug-build logs prefixed [FcmPushKit].'],
], [58, 52, 60])
table([
    ['PushNotificationTap', 'Description'],
    [c('data'), 'FCM data payload (all values are strings).'],
    [c('source'), 'TapSource.foreground, background or terminated.'],
    [c('route'), 'Value of data[routeKey], e.g. /details.'],
    [c('location'), 'Route plus the other data keys as query parameters, e.g. /details?id=42.'],
    [c('messageId'), 'FCM message ID when available.'],
], [40, 130])

# ---------------------------------------------------------------- 10
H1('10. Payload contract and sending notifications')
P('Always send a <b>notification</b> block (title/body, so the OS shows it in the '
  'background) plus a <b>data</b> block (for navigation). Data values must be strings.')
code('''
{
  "notification": { "title": "Order shipped", "body": "Tap to see details" },
  "data":         { "route": "/details", "id": "42" }
}
-> tap opens /details?id=42
''')
H2('Quick test from the Firebase console')
steps([
    'Run the app on a device, press <b>Copy FCM Token</b> (also printed in the console as FCM TOKEN).',
    'Firebase console, then Messaging, then Create your first campaign, then Firebase '
    'Notification messages. Enter a title and text.',
    'Click <b>Send test message</b>, paste the token, then Test.',
    'For deep links, under Additional options, then Custom data add '
    + c('route = /details') + ' and ' + c('id = 42') + ' and publish the campaign to the app '
    '(or use the HTTP v1 request below).',
])
H2('From a backend: FCM HTTP v1 API')
code('''
POST https://fcm.googleapis.com/v1/projects/push-notification-bfe0b/messages:send
Authorization: Bearer <OAuth2 access token of a service account>
Content-Type: application/json

{
  "message": {
    "token": "<device FCM token>",          // or "topic": "all"
    "notification": { "title": "Order shipped", "body": "Tap to see details" },
    "data": { "route": "/details", "id": "42" },
    "android": { "notification": { "channel_id": "high_importance_channel" } },
    "apns": { "payload": { "aps": { "sound": "default" } } }
  }
}
''')
P('For a local test, an access token can be obtained with '
  + c('gcloud auth print-access-token') + ' (account with Firebase access). Backends should '
  'use the Firebase Admin SDK with a service account key from Project settings, then '
  'Service accounts. Never ship the service account key inside the app.')

H1('11. POC test checklist')
table([
    ['#', 'Scenario', 'Expected result', 'Android', 'iOS'],
    ['1', 'First launch', 'Permission prompt appears; token logged', '', ''],
    ['2', 'Foreground message', 'Banner shown once (no duplicate)', '', ''],
    ['3', 'Tap foreground banner', 'Opens /details?id=42', '', ''],
    ['4', 'Background message + tap', 'Tray/banner; tap opens target screen', '', ''],
    ['5', 'Terminated (swiped away) + tap', 'App starts on target screen', '', ''],
    ['6', 'Topic "all" message', 'Received without a token target', '', ''],
    ['7', 'Permission denied', 'App works; no notifications; no crash', '', ''],
    ['8', 'Reinstall app', 'New token issued (onTokenRefresh)', '', ''],
], [8, 50, 72, 20, 20])

H1('12. Troubleshooting')
table([
    ['Problem', 'Fix'],
    ['"Firebase CLI Login Failed"', 'See section 3: update CLI, ' + c('firebase login --reauth') +
     ', avoid VPN/proxy, or ' + c('--no-localhost') + '.'],
    ['"No Firebase App [DEFAULT] has been created"', 'Run ' + c('flutterfire configure') +
     '; check google-services.json / GoogleService-Info.plist exist.'],
    ['No notification on Android 13+', 'Permission denied: Settings, then Apps, then '
     'Notifications. Check channel ID matches the manifest.'],
    ['getToken() returns null on iOS', 'Real device needed; APNs key uploaded; Push '
     'Notifications capability; correct Team selected.'],
    ['Background works, terminated tap does nothing', 'Call ' + c('getInitialTap()') +
     ' after the first frame (not before runApp).'],
    ['Duplicate banner on iOS', 'Do not show local notifications on iOS; the package already '
     'avoids this.'],
    ['Android build error about desugaring', 'Add isCoreLibraryDesugaringEnabled and the '
     'desugar_jdk_libs dependency (section 6).'],
    ['Force-stopped app gets nothing (Android)', 'Expected OS behaviour after Force stop; '
     'swiping away from recents is fine.'],
], [55, 115])

H1('13. Rolling out to other projects')
steps([
    'Tag a release of the package: ' + c('git tag fcm_push_kit-v0.1.0 && git push --tags') + '.',
    'In the new app: add the git dependency (section 5) and ' + c('firebase_core') + '.',
    'Run ' + c('flutterfire configure') + ' against that app\'s Firebase project.',
    'Apply the Android (section 6) and iOS (section 7) checklists.',
    'Call ' + c('FcmPushKit.instance.initialize()') + ' and wire taps to the app\'s router (section 8).',
    'Run the test checklist (section 11) on a real Android phone and a real iPhone.',
])
P('Changes to the package: bump ' + c('version') + ' in its pubspec, update CHANGELOG.md, '
  'run ' + c('flutter test') + ' in packages/fcm_push_kit, then tag. Apps upgrade by changing '
  'their ref.')


def on_page(canvas, doc):
    canvas.saveState()
    canvas.setFont('Sans', 7.5)
    canvas.setFillColor(MUTED)
    if doc.page > 1:
        canvas.drawString(20 * mm, 12 * mm, 'fcm_push_kit: Push Notification POC')
        canvas.drawRightString(190 * mm, 12 * mm, f'Page {doc.page}')
    canvas.setStrokeColor(ACCENT)
    canvas.setLineWidth(2)
    canvas.line(20 * mm, 287 * mm, 190 * mm, 287 * mm)
    canvas.restoreState()


doc = SimpleDocTemplate(sys.argv[1], pagesize=A4, leftMargin=20 * mm, rightMargin=20 * mm,
                        topMargin=18 * mm, bottomMargin=18 * mm,
                        title='fcm_push_kit: Push Notification POC',
                        author='Soumya8792')
doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
print('wrote', sys.argv[1])
