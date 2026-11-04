---
name: osascript-ui-automation
description: Drive and verify native macOS application UI transitions with osascript and System Events, including named controls, focus, window placement, fullscreen transitions, and display geometry. Use when native state or interaction must be verified beyond a screenshot.
---

# AppleScript UI Automation

Define a bounded transition, observable expected result, repetition count, and
failure condition. Use this skill for native window/chrome/geometry behavior.
For application logic, use the project's deterministic tests as well.

When invoked through a project extension, retain its process/window names,
control paths, launch policy, timing, tracing, and evidence requirements.
Discover the actual accessibility hierarchy before applying example selectors.

## Session ownership and permissions

- Run only on macOS. The process running `osascript` needs Accessibility
  permission in System Settings → Privacy & Security → Accessibility.
- Attach to the intended existing app by default. Limit interactions to the
  user-authorized flow and verify the target process and frontmost app before
  any coordinate click. Do not click an unrelated foreground application.
- If launch is authorized, use the project's session supervisor when available.
  For a longer interactive debugging session, an explicitly owned launch with
  a recorded PID and stderr log is also valid. Immediately confirm its identity
  and retain ownership across round trips. Stop only a process this session
  created; do not use broad process-name termination.
- Detect multiple or overlapping instances before launch. Do not terminate an
  ambiguous existing instance to make a test proceed.
- Use an available native screenshot capability, preferably `app-screenshot`
  when installed. Screen Recording permission is separate from Accessibility.
  For absolute-position claims, preserve full-display evidence; a window crop
  cannot prove its position relative to the menu bar or display.
- Playback or other external stimulus follows the task's authorization and
  project policy; UI automation alone does not authorize it.

## Observe and interact

1. Identify the target process and content window. Record the frontmost app,
   initial logical position/size, display, and expected final geometry.
   Resolve windows by title or refreshed semantic identity rather than a
   retained numerical index: window lists can change during native transitions.

   ```bash
   osascript -e '
   tell application "System Events"
       tell process "ExampleApp"
           set content_window to first window whose name is "Example Document"
           return {position of content_window, size of content_window}
       end tell
   end tell'
   osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true'
   ```

2. Capture the initial full-display state when placement matters. Prefer named
   accessibility controls over coordinates. Substitute the observed hierarchy
   for this example; a group index is not a universal application convention.

   ```bash
   osascript -e '
   tell application "System Events"
       tell process "ExampleApp"
           click button "Settings" of window "Example Document"
       end tell
   end tell'
   ```

3. Re-query windows and controls after each state/mode transition. If a control
   is temporarily absent, wait within the declared timeout and observe again.
   Use bounded settling checks where possible; choose delays appropriate to the
   application/OS animation rather than prescribing one fixed delay globally.

4. Use coordinates only when a refreshed semantic lookup is unavailable.
   Capture the current state, establish the target display's backing scale,
   account for image-viewer resizing, and compute each axis:

   ```text
   logical_point = displayed_pixel * original_capture_pixels / displayed_image_pixels / backing_scale
   ```

   This conversion assumes an image and logical coordinates with corresponding
   origins. Account separately for a display/crop offset before using an
   absolute coordinate. Never reuse a scale, origin, or control position from
   another display, capture, build layout, or application mode.

5. Re-check focus immediately before a coordinate click:

   ```bash
   osascript -e 'tell application "System Events" to click at {X, Y}'
   ```

   Perform an uncertain first action separately and verify its state before
   batching further actions. A returned accessible element is supporting
   evidence; verify that the intended transition actually occurred.

6. Capture the final full-display state and query the content-window geometry
   again. Compare observed logical coordinates and semantic state with the
   declared acceptance criteria. Repeat timing-sensitive round trips two or
   three times in the same owned lifetime when that repetition is in scope.

## Diagnose failures

If assistive access fails, inspect permission/prompt state and focus before
retrying. A partially completed click sequence can leave the application in a
different state than an error message suggests. Obtain fresh state evidence
before deciding which action, if any, is safe to retry; toggles can reverse an
already successful transition. Stop a stale coordinate sequence after a real
miss, re-capture, and re-derive its target.

When external observation cannot explain a failure, correlate it with focused
application-side tracing: requested state, queued transition, actual inner /
outer geometry, and settled state. Include the surrounding flags/modes that
could confound the hypothesis. Use the project's gated tracing mechanisms and
avoid leaving raw hot-path logging from a temporary investigation.

Preserve successful and failed screenshots/logs. Report target identity,
initial/final logical geometry, display/scale, each repetition's outcome,
inspected evidence paths, relevant traces, and cleanup ownership/result.
Distinguish observed placement evidence from an inferred cause.
