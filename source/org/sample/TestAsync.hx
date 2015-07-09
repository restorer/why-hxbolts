package org.sample;

#if test_async

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

class TestAsync implements async.Build implements TestTask {
    public function new() : Void {
        trace("[ async ]");
    }

    private function fetchText(url : String, callback : Dynamic -> String -> Void) : Void {
        var urlLoader = new URLLoader();

        var onLoaderError = function(e : Event) : Void {
            callback(e.type, null);
        };

        urlLoader.addEventListener(Event.COMPLETE, function(_) : Void {
            callback(null, Std.string(urlLoader.data));
        });

        urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
        urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

        try {
            urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
            urlLoader.load(new URLRequest(url));
        } catch (e : Dynamic) {
            callback(Std.string(e), null);
        }
    }

    @async
    private function fetchJson(url : String) : DynamicExt {
        [var result] = fetchText(url);
        return cast Json.parse(result);
    }

    private function fetchBitmapData(url : String, callback : Dynamic -> BitmapData -> Void) : Void {
        var loader = new Loader();

        var onLoaderError = function(e : Event) : Void {
            callback(e.type, null);
        };

        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(_) : Void {
            callback(null, (cast loader.content:Bitmap).bitmapData);
        });

        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
        loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

        try {
            loader.load(new URLRequest(url), new LoaderContext(true));
        } catch (e : Dynamic) {
            callback(Std.string(e), null);
        }
    }

    @async
    private function sendApiRequest(method : String) : DynamicExt {
        [var result] = fetchJson('http://some.api/${method}');

        if (result["error"] != null) {
            throw result["error"].asString();
        }

        return result;
    }

    @async
    private function syncState() : Void {
        [var result] = sendApiRequest("sync-state");
        Runner.updateStateFromTheResponse(result);

        if (result.exists("playerAvatarUrl")) {
            [var bitmapData] = fetchBitmapData(result["playerAvatarUrl"].asString());
            Runner.setPlayerAvatar(bitmapData);
        }

        if (result.exists("opponentAvatarUrl")) {
            [var bitmapData] = fetchBitmapData(result["opponentAvatarUrl"].asString());
            Runner.setOpponentAvatar(bitmapData);
        }
    }

    public function doTheTask() : Void {
        Runner.showLoader();

        syncState(function(err : Dynamic) : Void {
            Runner.hideLoader();

            if (err == null) {
                Runner.onTaskSuccessed();
            } else {
                Runner.showErrorPopup();
            }
        });
    }
}

#end
