#  <#Notes#>

Currernt implementation:
based on LiveCameraSwiftUI if using `FrameHandler` and `FrameView`
based on DetectorAppSwiftUI if using `HostedViewController`

both seem to work about equally


Debugging:
Error:
Read an unowned reference but the object was already destroyed
Fatal error: Attempted to read an unowned reference but the object was already destroyed


## Using FrameHandler/FrameView ... (LiveCameraSwiftUI)
```desiredFPS: 240.0
format: <AVCaptureDeviceFormat: 0x1103d4280 'vide'/'420f' 1920x1080, { 1-240 fps}, photo dims:{1920x1080}, fov:74.597, binned, supports vis (modes: standard) (max strength:Low), max zoom:67.50 (upscales @1.00), system zoom range:1.0-6.0, AF System:2, ISO:54.0-2160.0, SS:0.000023-1.000000, system exposure bias range:-2.0-2.0, supports wide color, supports Smudge Detection>
frameRateRange: Optional(<AVFrameRateRange: 0x1103ed940 1 - 240>)
max width: 1920
```
black screen, but displays fps


## Using HostedViewController ... (DetectorAppSwiftUI)
Runs, video sideways, prints `running fps: ...`

```warning, deleted thread with uncommitted CATransaction; set CA_DEBUG_TRANSACTIONS=1 in environment to log backtraces, or set CA_ASSERT_MAIN_THREAD_TRANSACTIONS=1 to abort when an implicit transaction isn't created on a main thread.```






Other camera / video articles and implementations:

http://taylorfranklin.me/2015/01/20/ios-tutorial-developing-240-fps/

Sample code:

| Project | metal? | works? | Messes up camera? | crashes? | platform |
| --- | --- | --- | --- | --- | --- |
|  FlickerFindr       |  no | yes |  no |  | SwiftUI (?) |
|  DetectorAppSwiftUI |  no |  no |  no |  | SwiftUi |
|  LiveCameraSwiftUI  |  no |  no |  no |  | SwiftUI |
|  CreateVisEffectsWSwiftUI -- no cam  |  no |  no | yes |  | SwiftUI |
|  AVCamFilter        |  no |  no | yes |  | AppKit |
|  TrueDepthBackdrop  |  no |  no | yes |  | AppKit |


This is the error I get in both `AVCamFilter` and `TrueDepthBackdrop`:
```
failure in void _UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption(void)_block_invoke (UIApplication_RuntimeIssues.m:106) : Application failed to launch: UIScene life cycle is required for apps built with this SDK. See "Transitioning to the UIKit scene-based life cycle" in the UIKit documentation for more information on migration.
```

