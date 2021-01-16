#!/usr/bin/python
# -*- coding: utf-8 -*-

import time
import plistlib
import os
import subprocess

# https://stackoverflow.com/questions/6337513/how-can-i-debug-a-launchd-script-that-doesnt-run-on-startup


def run_applescript(script, app):
    try:
        result = subprocess.check_output(
            [
                "/usr/bin/osascript",
                "-e",
                "on run argv",
                "-e",
                "try",
                "-e",
                script,
                "-e",
                "end try",
                "-e",
                "end run",
                app,
            ]
        ).rstrip()
        return result
    except subprocess.CalledProcessError as err:
        print("catched error: {}".format(err))


def is_running(app):
    return (
        run_applescript("return application id (item 1 of argv) is running", app)
        == "true"
    )


def is_hidden(app):
    script = """
        tell application "System Events"
            return visible of (application process 1 whose bundle identifier is (item 1 of argv))
        end tell
    """
    return run_applescript(script, app) == "true"


def is_frontmost(app):
    return (
        run_applescript("return application id (item 1 of argv) is frontmost", app)
        == "true"
    )


def hide_app(app):
    script = """
        tell application "System Events"
            tell (application process 1 whose bundle identifier is (item 1 of argv))
                set visible to false
            end tell
        end tell
    """
    run_applescript(script, app)


def quit_app(app):
    run_applescript("tell application id (item 1 of argv) to quit", app)


PLIST_PATH = os.path.expanduser(
    "~/Library/Preferences/com.rb.hs.appquitter.tracker.plist"
)
plist_obj = plistlib.readPlist(PLIST_PATH)

new_plist = {}

for bundle_id in plist_obj:
    if not is_running(bundle_id):
        # if the app is already not running, it's not interesting anymore
        continue

    if is_frontmost(bundle_id):
        # if the app frontmost, don't touch it
        continue

    for operation_key in plist_obj[bundle_id]:
        scheduled_action_time = plist_obj[bundle_id][operation_key]

        # we haven't reached the deadline yet. Keep in .plist
        if scheduled_action_time > time.time():
            if bundle_id not in new_plist:
                new_plist[bundle_id] = {}
            new_plist[bundle_id][operation_key] = scheduled_action_time
            continue

        if operation_key == "quit":
            quit_app(bundle_id)
        if operation_key == "hide":
            hide_app(bundle_id)


plistlib.writePlist(new_plist, PLIST_PATH)
