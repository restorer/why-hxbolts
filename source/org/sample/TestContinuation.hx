package org.sample;

#if test_continuation

import com.dongxiguo.continuation.Continuation;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import haxe.Json;
import haxe.ds.Either;
import org.sample.fake.Loader;
import org.sample.fake.LoaderContext;
import org.sample.fake.Runner;
import org.sample.fake.TestTask;
import org.sample.fake.URLLoader;
import org.sample.fake.URLLoaderDataFormat;
import org.sample.fake.URLRequest;
import org.zamedev.lib.DynamicExt;

using org.zamedev.lib.DynamicTools;
using StringTools;

@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":async"))
class TestContinuation implements TestTask {
    public function new() : Void {
        trace("[ continuation ]");
    }

    private function fetchText(url : String, callback : Either<String, String> -> Void) : Void {
        var urlLoader = new URLLoader();

        var onLoaderError = function(e : Event) : Void {
            callback(Either.Left(e.type));
        };

        urlLoader.addEventListener(Event.COMPLETE, function(_) : Void {
            callback(Either.Right(Std.string(urlLoader.data)));
        });

        urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
        urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

        try {
            urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
            urlLoader.load(new URLRequest(url));
        } catch (e : Dynamic) {
            callback(Either.Left(Std.string(e)));
        }
    }

    private function fetchJsonTryCatcher(v : DynamicExt) : Either<String, DynamicExt> {
        try {
            return Either.Right(cast Json.parse(v));
        } catch (e : Dynamic) {
            return Either.Left(Std.string(e));
        }
    }

    @:async
    private function fetchJson(url : String) : Either<String, DynamicExt> {
        switch (@await fetchText(url)) {
            case Left(v):
                return Either.Left(v);

            case Right(v): {
                /*
                 * Compile error:
                 *
                try {
                    return Either.Right(cast Json.parse(v));
                } catch (e : Dynamic) {
                    return Either.Left(Std.string(e));
                }
                */

                // But this compiles successfully:
                return fetchJsonTryCatcher(v);
            }
        }
    }

    private function fetchBitmapData(url : String, callback : Either<String, BitmapData> -> Void) : Void {
        var loader = new Loader();

        var onLoaderError = function(e : Event) : Void {
            callback(Either.Left(e.type));
        };

        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(_) : Void {
            callback(Either.Right((cast loader.content:Bitmap).bitmapData));
        });

        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
        loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

        try {
            loader.load(new URLRequest(url), new LoaderContext(true));
        } catch (e : Dynamic) {
            callback(Either.Left(Std.string(e)));
        }
    }

    @:async
    private function sendApiRequest(method : String) : Either<String, DynamicExt> {
        switch (@await fetchJson('http://some.api/${method}')) {
            case Left(v):
                return Either.Left(v);

            case Right(v):
                if (v["error"] != null) {
                    return Either.Left(v["error"].asString());
                } else {
                    return Either.Right(v);
                }
        }
    }

    @:async
    private function syncState() : Bool {
        switch (@await sendApiRequest("sync-state")) {
            case Left(v):
                return false;

            case Right(v): {
                var result = true;
                Runner.updateStateFromTheResponse(v);

                if (v.exists("playerAvatarUrl")) {
                    switch (@await fetchBitmapData(v["playerAvatarUrl"])) {
                        case Left(v):
                            result = false;

                        case Right(v):
                            Runner.setPlayerAvatar(v);
                    }
                }

                if (v.exists("opponentAvatarUrl")) {
                    switch (@await fetchBitmapData(v["opponentAvatarUrl"])) {
                        case Left(v):
                            result = false;

                        case Right(v):
                            Runner.setOpponentAvatar(v);
                    }
                }

                return result;
            }
        }
    }

    public function doTheTask() : Void {
        Runner.showLoader();

        syncState(function(result : Bool) : Void {
            Runner.hideLoader();

            if (result) {
                Runner.onTaskSuccessed();
            } else {
                Runner.showErrorPopup();
            }
        });
    }
}

#end
