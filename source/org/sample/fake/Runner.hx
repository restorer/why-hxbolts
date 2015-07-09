package org.sample.fake;

import flash.display.BitmapData;
import org.zamedev.lib.DynamicExt;

using org.zamedev.lib.DynamicTools;
using StringTools;

class Runner {
    private static var testTask : TestTask;
    private static var alreadyInLoop : Bool = false;
    private static var wasFailed : Bool = false;

    public static function updateStateFromTheResponse(response : DynamicExt) : Void {
        Variants.stateUpdated = true;
    }

    public static function setPlayerAvatar(bitmapData : BitmapData) : Void {
        Variants.playerAvatarUpdated = (bitmapData != null);
    }

    public static function setOpponentAvatar(bitmapData : BitmapData) : Void {
        Variants.opponentAvatarUpdated = (bitmapData != null);
    }

    public static function showLoader() : Void {
        Variants.loaderShown = true;
    }

    public static function hideLoader() : Void {
        Variants.loaderShown = false;
    }

    public static function onTaskSuccessed() : Void {
        Variants.everythingSuccessed = true;

        if (!Variants.check()) {
            wasFailed = true;
        }

        nextLoop();
    }

    public static function showErrorPopup() : Void {
        Variants.errorPopupShown = true;

        if (!Variants.check()) {
            wasFailed = true;
        }

        nextLoop();
    }

    private static function nextLoop() : Void {
        if (alreadyInLoop) {
            wasFailed = true;
            return;
        }

        alreadyInLoop = true;

        haxe.Timer.delay(function() {
            if (!wasFailed) {
                loop();
            }
        }, 10);
    }

    private static function loop() : Void {
        if (Variants.next()) {
            Variants.traceCondition();

            wasFailed = false;
            alreadyInLoop = false;

            testTask.doTheTask();
        } else {
            trace("EVERYTHING IS OK");
        }
    }

    public static function run(_testTask : TestTask) : Void {
        // Variants.urlLoaderVariant = URLLoaderVariant.ResponseDataAndBothAvatars;
        // Variants.playerAvatarLoaderVariant = LoaderVariant.Response;
        // Variants.opponentAvatarLoaderVariant = LoaderVariant.DispatchSecurityError;

        testTask = _testTask;
        loop();
    }
}
