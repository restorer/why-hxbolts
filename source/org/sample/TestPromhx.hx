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
            // dp.resolve() - ok, but why dp.throwError() instead of dp.reject() ?
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
            // (on it or on promise of it), but **will** throw in other case
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

    private function syncState() : Promise<Bool> {
        // 1. if "then" instead of "pipe" - Type Coercion failed: cannot convert promhx::Promise to Array.

        // 2. unfortunately when error happened, catchError called immediately, and
        // when several promises awaiting, than catchError handler can be called first,
        // and promise can be resolved later. to fix it subPromises returns Bool now.

        // 3. still must catch errors.

        return cast sendApiRequest("sync-state").pipe(function(result : DynamicExt) : Promise<Bool> {
            var subPromises = new Array<Promise<Bool>>();
            Runner.updateStateFromTheResponse(result);

            if (result.exists("playerAvatarUrl")) {
                subPromises.push(cast fetchBitmapData(result["playerAvatarUrl"].asString()).then(function(bmd : BitmapData) : Bool {
                    Runner.setPlayerAvatar(bmd);
                    return true;
                }).errorThen(function(e : Dynamic) : Bool {
                    return false;
                }));
            }

            if (result.exists("opponentAvatarUrl")) {
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
