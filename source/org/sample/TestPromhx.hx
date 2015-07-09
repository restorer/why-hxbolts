package org.sample;

#if test_promhx

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import haxe.Json;
import haxe.Timer;
import org.sample.fake.Loader;
import org.sample.fake.LoaderContext;
import org.sample.fake.Runner;
import org.sample.fake.TestTask;
import org.sample.fake.URLLoader;
import org.sample.fake.URLLoaderDataFormat;
import org.sample.fake.URLRequest;
import org.zamedev.lib.DynamicExt;
import promhx.Deferred;
import promhx.Promise;

using org.zamedev.lib.DynamicTools;
using StringTools;

class TestPromhx implements TestTask {
    public function new() : Void {
        trace("[ promhx ]");
    }

    private function fetchText(url : String) : Promise<String> {
        var dp = new Deferred<String>();
        var urlLoader = new URLLoader();

        var onLoaderError = function(e : Event) : Void {
            dp.throwError(e.type);
        };

        urlLoader.addEventListener(Event.COMPLETE, function(_) : Void {
            dp.resolve(Std.string(urlLoader.data));
        });

        urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
        urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

        try {
            urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
            urlLoader.load(new URLRequest(url));
        } catch (e : Dynamic) {
            // dp.throwError() will not actually throw an error if there is any error handlers
            // (on it or on promise of it), but **will** throw in other case.
            //
            // Exact test case: without Timer.delay() you'll get following exception for neko target:
            //
            // Variants.hx:20: OK : false / false / false / false / false / true
            // Variants.hx:16: 8 / 1 / 1 ...
            // Example urlloader error
            // Called from promhx/base/AsyncBase.hx line 169
            // ...

            Timer.delay(function() : Void {
                dp.throwError(Std.string(e));
            }, 0);
        }

        return dp.promise();
    }

    private function fetchJson(url : String) : Promise<DynamicExt> {
        return fetchText(url).then(function(result : String) : DynamicExt {
            return cast Json.parse(result);
        });
    }

    private function fetchBitmapData(url : String) : Promise<BitmapData> {
        var dp = new Deferred<BitmapData>();
        var loader = new Loader();

        var onLoaderError = function(e : Event) : Void {
            dp.throwError(e.type);
        };

        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(_) : Void {
            dp.resolve((cast loader.content:Bitmap).bitmapData);
        });

        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
        loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

        try {
            loader.load(new URLRequest(url), new LoaderContext(true));
        } catch (e : Dynamic) {
            Timer.delay(function() : Void {
                dp.throwError(Std.string(e));
            }, 0);
        }

        return dp.promise();
    }

    private function sendApiRequest(method : String) : Promise<DynamicExt> {
        return fetchJson('http://some.api/${method}').then(function(result : DynamicExt) : DynamicExt {
            if (result["error"] != null) {
                throw result["error"];
            }

            return result;
        });
    }

    /*
     * This version fails for neko:
     *
     * Variants.hx:20: OK : false / true / false / false / false / true
     * Variants.hx:16: 1 / 2 / 1 ...
     * Variants.hx:20: FAILURE : false / true / true / false / false / true
     *
     * and randomly (not every time) fails for flash:
     *
     * Variants.hx:16: 1 / 2 / 1 ...
     * Variants.hx:20: OK : false / true / false / true / false / true
     * Variants.hx:16: 1 / 2 / 2 ...
     * Variants.hx:20: OK : false / true / false / false / false / true
     * Variants.hx:20: OK : false / true / false / false / false / true
     *
    private function syncState() : Promise<Array<Void>> {
        return sendApiRequest("sync-state").pipe(function(result : DynamicExt) : Promise<Array<Void>> {
            var subPromises = new Array<Promise<Void>>();
            Runner.updateStateFromTheResponse(result);

            if (result.exists("playerAvatarUrl")) {
                subPromises.push(fetchBitmapData(result["playerAvatarUrl"].asString()).then(function(bmd : BitmapData) : Void {
                    Runner.setPlayerAvatar(bmd);
                }));
            }

            if (result.exists("opponentAvatarUrl")) {
                subPromises.push(fetchBitmapData(result["opponentAvatarUrl"].asString()).then(function(bmd : BitmapData) : Void {
                    Runner.setOpponentAvatar(bmd);
                }));
            }

            return Promise.whenAll(subPromises);
        });
    }

    public function doTheTask() : Void {
        Runner.showLoader();

        syncState().then(function(_) : Void {
            Runner.hideLoader();
            Runner.onTaskSuccessed();
        }).catchError(function(e : Dynamic) : Void {
            Runner.hideLoader();
            Runner.showErrorPopup();
        });
    }
    */

    // This version works:
    private function syncState() : Promise<Bool> {
        // without cast: promhx.base.AsyncBase<Bool> should be promhx.Promise<Bool>
        return cast sendApiRequest("sync-state").pipe(function(result : DynamicExt) : Promise<Bool> {
            var subPromises = new Array<Promise<Bool>>();
            Runner.updateStateFromTheResponse(result);

            if (result.exists("playerAvatarUrl")) {
                // without cast: promhx.base.AsyncBase<Bool> should be promhx.Promise<Bool>
                subPromises.push(cast fetchBitmapData(result["playerAvatarUrl"].asString()).then(function(bmd : BitmapData) : Bool {
                    Runner.setPlayerAvatar(bmd);
                    return true;
                }).errorThen(function(e : Dynamic) : Bool {
                    return false;
                }));
            }

            if (result.exists("opponentAvatarUrl")) {
                // without cast: promhx.base.AsyncBase<Bool> should be promhx.Promise<Bool>
                subPromises.push(cast fetchBitmapData(result["opponentAvatarUrl"].asString()).then(function(bmd : BitmapData) : Bool {
                    Runner.setOpponentAvatar(bmd);
                    return true;
                }).errorThen(function(e : Dynamic) : Bool {
                    return false;
                }));
            }

            return Promise.whenAll(subPromises).then(function(list : Array<Bool>) : Bool {
                for (val in list) {
                    if (!val) {
                        return false;
                    }
                }

                return true;
            });
        }).errorThen(function(e : Dynamic) : Bool {
            return false;
        });
    }

    public function doTheTask() : Void {
        Runner.showLoader();

        syncState().then(function(success : Bool) : Void {
            Runner.hideLoader();

            if (success) {
                Runner.onTaskSuccessed();
            } else {
                Runner.showErrorPopup();
            }
        });
    }
}

#end
