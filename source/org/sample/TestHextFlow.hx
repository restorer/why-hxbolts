package org.sample;

#if test_hextflow

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import haxe.Json;
import haxe.Timer;
import hext.flow.Promise;
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

class TestHextFlow implements TestTask {
    public function new() : Void {
        trace("[ hext-flow ]");
    }

    private function fetchText(url : String) : Promise<String> {
        var resultPromise = new Promise<String>();
        var urlLoader = new URLLoader();

        var onLoaderError = function(e : Event) : Void {
            resultPromise.reject(null);
        };

        urlLoader.addEventListener(Event.COMPLETE, function(_) : Void {
            resultPromise.resolve(Std.string(urlLoader.data));
        });

        urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
        urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

        try {
            urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
            urlLoader.load(new URLRequest(url));
        } catch (e : Dynamic) {
            Timer.delay(function() : Void {
                resultPromise.reject(null);
            }, 0);
        }

        return resultPromise;
    }

    private function fetchJson(url : String) : Promise<DynamicExt> {
        var resultPromise = new Promise<DynamicExt>();
        var fetchTextPromise = fetchText(url);

        fetchTextPromise.resolved(function(v : String) : Void {
            try {
                resultPromise.resolve(cast Json.parse(v));
            } catch (e : Dynamic) {
                resultPromise.reject(null);
            }
        });

        fetchTextPromise.rejected(function(_) : Void {
            resultPromise.reject(null);
        });

        return resultPromise;
    }

    private function fetchBitmapData(url : String) : Promise<BitmapData> {
        var resultPromise = new Promise<BitmapData>();
        var loader = new Loader();

        var onLoaderError = function(e : Event) : Void {
            resultPromise.reject(null);
        };

        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(_) : Void {
            resultPromise.resolve((cast loader.content:Bitmap).bitmapData);
        });

        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
        loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

        try {
            loader.load(new URLRequest(url), new LoaderContext(true));
        } catch (e : Dynamic) {
            Timer.delay(function() : Void {
                resultPromise.reject(null);
            }, 0);
        }

        return resultPromise;
    }

    private function sendApiRequest(method : String) : Promise<DynamicExt> {
        var resultPromise = new Promise<DynamicExt>();
        var fetchJsonPromise = fetchJson('http://some.api/${method}');

        fetchJsonPromise.resolved(function(v : DynamicExt) : Void {
            if (v["error"] != null) {
                resultPromise.reject(null);
            } else {
                resultPromise.resolve(v);
            }
        });

        fetchJsonPromise.rejected(function(_) : Void {
            resultPromise.reject(null);
        });

        return resultPromise;
    }

    private function syncState() : Promise<Dynamic> {
        var sendApiRequestPromise = sendApiRequest("sync-state");
        var resultPromise = new Promise<Dynamic>();

        sendApiRequestPromise.resolved(function(v : DynamicExt) : Void {
            Runner.updateStateFromTheResponse(v);

            var subPromises : Array<Promise<Dynamic>> = [];
            var success = true;

            if (v.exists("playerAvatarUrl")) {
                var subPromise = new Promise<Dynamic>();
                var fetchBitmapDataPromise = fetchBitmapData(v["playerAvatarUrl"].asString());

                fetchBitmapDataPromise.resolved(function(v : BitmapData) : Void {
                    Runner.setPlayerAvatar(v);
                    subPromise.resolve(null);
                });

                fetchBitmapDataPromise.rejected(function(_) : Void {
                    success = false;
                    subPromise.resolve(null);
                });

                subPromises.push(subPromise);
            }

            if (v.exists("opponentAvatarUrl")) {
                var subPromise = new Promise<Dynamic>();
                var fetchBitmapDataPromise = fetchBitmapData(v["opponentAvatarUrl"].asString());

                fetchBitmapDataPromise.resolved(function(v : BitmapData) : Void {
                    Runner.setOpponentAvatar(v);
                    subPromise.resolve(null);
                });

                fetchBitmapDataPromise.rejected(function(_) : Void {
                    success = false;
                    subPromise.resolve(null);
                });

                subPromises.push(subPromise);
            }

            if (subPromises.length != 0) {
                Promise.when(subPromises).resolved(function(_) : Void {
                    if (success) {
                        resultPromise.resolve(null);
                    } else {
                        resultPromise.reject(null);
                    }
                });
            } else {
                resultPromise.resolve(null);
            }
        });

        sendApiRequestPromise.rejected(function(_) : Void {
            resultPromise.reject(null);
        });

        return resultPromise;
    }

    public function doTheTask() : Void {
        Runner.showLoader();
        var syncStatePromise = syncState();

        syncStatePromise.done(function(_) : Void {
            Runner.hideLoader();

            if (syncStatePromise.isResolved()) {
                Runner.onTaskSuccessed();
            } else {
                Runner.showErrorPopup();
            }
        });
    }
}

#end
