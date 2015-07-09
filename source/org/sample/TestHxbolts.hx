package org.sample;

#if test_hxbolts

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import haxe.Json;
import hxbolts.Task;
import hxbolts.TaskCompletionSource;
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

class TestHxbolts implements TestTask {
    public function new() : Void {
        trace("[ hxbolts ]");
    }

    private function fetchText(url : String) : Task<String> {
        var tcs = new TaskCompletionSource<String>();
        var urlLoader = new URLLoader();

        var onLoaderError = function(e : Event) : Void {
            tcs.setError(e.type);
        };

        urlLoader.addEventListener(Event.COMPLETE, function(_) : Void {
            tcs.setResult(Std.string(urlLoader.data));
        });

        urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
        urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

        try {
            urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
            urlLoader.load(new URLRequest(url));
        } catch (e : Dynamic) {
            tcs.setError(Std.string(e));
        }

        return tcs.task;
    }

    private function fetchJson(url : String) : Task<DynamicExt> {
        return fetchText(url).onSuccess(function(task : Task<String>) : DynamicExt {
            return cast Json.parse(task.result);
        });
    }

    private function fetchBitmapData(url : String) : Task<BitmapData> {
        var tcs = new TaskCompletionSource<BitmapData>();
        var loader = new Loader();

        var onLoaderError = function(e : Event) : Void {
            tcs.setError(e.type);
        };

        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(_) : Void {
            tcs.setResult((cast loader.content:Bitmap).bitmapData);
        });

        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
        loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

        try {
            loader.load(new URLRequest(url), new LoaderContext(true));
        } catch (e : Dynamic) {
            tcs.setError(Std.string(e));
        }

        return tcs.task;
    }

    private function sendApiRequest(method : String) : Task<DynamicExt> {
        return fetchJson('http://some.api/${method}').onSuccess(function(task : Task<DynamicExt>) : DynamicExt {
            if (task.result["error"] != null) {
                throw task.result["error"];
            }

            return task.result;
        });
    }

    private function syncState() : Task<Void> {
        return sendApiRequest("sync-state").onSuccessTask(function(task : Task<DynamicExt>) : Task<Void> {
            var subTasks = new Array<Task<Void>>();
            Runner.updateStateFromTheResponse(task.result);

            if (task.result.exists("playerAvatarUrl")) {
                subTasks.push(fetchBitmapData(task.result["playerAvatarUrl"].asString()).onSuccess(function(t : Task<BitmapData>) : Void {
                    Runner.setPlayerAvatar(t.result);
                }));
            }

            if (task.result.exists("opponentAvatarUrl")) {
                subTasks.push(fetchBitmapData(task.result["opponentAvatarUrl"].asString()).onSuccess(function(t : Task<BitmapData>) : Void {
                    Runner.setOpponentAvatar(t.result);
                }));
            }

            return Task.whenAll(subTasks);
        });
    }

    public function doTheTask() : Void {
        Runner.showLoader();

        syncState().continueWith(function(task : Task<Void>) : Void {
            Runner.hideLoader();

            if (task.isSuccessed) {
                Runner.onTaskSuccessed();
            } else {
                Runner.showErrorPopup();
            }
        });
    }
}

#end
