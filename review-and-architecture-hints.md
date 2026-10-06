# Review and architecture hints: Touchdown for SailfishOS

For anyone reviewing the `sailfishos` branch: where the code comes from, how it is laid out, what is worth reading and what is boilerplate.

## Where the code comes from

The app is the AsteroidOS watch app on `main`. This branch forks from it at `52fcb8e`, and its commits are the SailfishOS port. The reliable view of what the port changed:

    git diff 52fcb8e sailfishos -- qml src rpm '*.pro' '*.desktop'

Many port edits carry a `SailfishOS:` comment, but not all of them. Each commit message says what changed, why, and what was not checked, and ends with an LLMGD line grading it.

The port was written by an LLM (Claude), directed and tested by the author, who has not read the code. Everything here is a prototype until a reviewer owns it. That is the point of this file.

## Architecture

- `qml/harbour-asteroid-touchdown.qml`: the Silica `ApplicationWindow`. It sizes `Dims` from the screen width, then loads the app (`game/main.qml`). When the app goes to the background, the same item is moved into the cover and scaled down, so the home screen tile shows it live. The same shell is used in all eight ports.
- `qml/game/Dims.qml`, `Label.qml`, `HighlightBar.qml`, `Icon.qml`, `PageHeader.qml`, `ValueCycler.qml`, `IntSelector.qml`, `DeviceSpecs.qml` (whichever exist here): small stand-ins for AsteroidOS's `org.asteroid.controls` and `org.asteroid.utils`, so the watch QML runs unchanged where possible. Each is a few dozen lines.
- `qml/game/main.qml` (about 1300 lines) is the game, with tuning blocks first: physics (~35), viewport (~84), world generation (~113). Then state, the accelerometer baseline (~194), the derived viewport (~200), world generation (~254), the 60 fps physics tick (~408), UFO (~456), surface contact (~489), landing and crash (~579, ~587), haptics (~637), and the visual tree from ~711.
- `StartOverlay.qml`, `GameOverOverlay.qml`, `CommsMessages.qml`, `UfoObstacle.qml`, `DeathShader.qml`: self-contained parts.
- `qml/game/TouchdownStorage.qml`: QML singleton for unlocked level, best time per level and the combo record and state, kept in dconf (`/apps/harbour-asteroid-touchdown`). It replaced a C++ QSettings class with the same API.
- Packaging: pure QML, no binary. `Exec=sailfish-qml harbour-asteroid-touchdown` (package `libsailfishapp-launcher`), the `.pro` is `TEMPLATE = aux` with plain `INSTALLS`, and the spec is `BuildArch: noarch` with an xz payload (rpm 4.14 on SailfishOS 3.4 can not unpack the zstd of newer SDKs).

## Read these first

1. Viewport tuning and the derived viewport: the camera rework for the tall screen. The world is sized from `viewport.refSize` = 480, an **assumption** chosen so that gravity and thrust feel as they did on the watch. Without it, the world grew with the screen while the forces stayed fixed (free fall took 10.5 s instead of 8.5 s). `tallZoomBlend` = 0.5 (around line 210), also a judgement call, blends the camera span between the square watch view and the full tall screen; the landing close-up's zoom is derived from that span.
2. The physics tick and surface contact: the game itself.
3. `TouchdownStorage.qml`: best times only improve, and the unlocked level and combo record never go down.

## Skim

Stand-ins, icons, `img/`, packaging.

## Worth questioning

- The landing close-up is borderline choppy on the Jolla Tablet's GPU.
- Permissions: `Camera`, not `Sensors` (see the README). The camera is never opened.
- Progress from before 1.1.0 is not migrated.

## How it was tested

By the author, by playing it on a Jolla C2 (SailfishOS 5.1), the Jolla Tablet (4.6, x86) and a Jolla 1 (3.4, 32-bit ARM), with the same noarch package on all three. Before each handover, the LLM checked builds, package contents and start logs on those devices.

There are no automated tests; the on-device checks are listed in the commit messages.
