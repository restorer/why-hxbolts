package org.sample;

#if test_thxpromise

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import haxe.Json;
import org.sample.fake.Loader;
import org.sample.fake.LoaderContext;
import org.sample.fake.Runner;
import org.sample.fake.TestTask;
import org.sample.fake.URLLoader;
import org.sample.fake.URLLoaderDataFormat;
import org.sample.fake.URLRequest;
import org.zamedev.lib.DynamicExt;
import thx.Error;
import thx.Nil;
import thx.Result;
import thx.promise.Promise;

using thx.Arrays;
using org.zamedev.lib.DynamicTools;
using StringTools;

class TestThxPromise implements TestTask {
    public function new() : Void {
        trace("[ thx.promise ]");
    }

    private function fetchText(url : String) : Promise<String> {
        return Promise.create(function(resolve : String -> Void, reject : Error -> Void) : Void {
            var urlLoader = new URLLoader();

            var onLoaderError = function(e : Event) : Void {
                reject(Error.fromDynamic(e.type));
            };

            urlLoader.addEventListener(Event.COMPLETE, function(_) : Void {
                resolve(Std.string(urlLoader.data));
            });

            urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

            try {
                urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
                urlLoader.load(new URLRequest(url));
            } catch (e : Dynamic) {
                reject(Error.fromDynamic(Std.string(e)));
            }
        });
    }

    private function fetchJson(url : String) : Promise<DynamicExt> {
        return fetchText(url).mapSuccess(function(result : String) : DynamicExt {
            return cast Json.parse(result);
        });
    }

    private function fetchBitmapData(url : String) : Promise<BitmapData> {
        return Promise.create(function(resolve : BitmapData -> Void, reject : Error -> Void) : Void {
            var loader = new Loader();

            var onLoaderError = function(e : Event) : Void {
                reject(Error.fromDynamic(Std.string(e)));
            };

            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(_) : Void {
                resolve((cast loader.content:Bitmap).bitmapData);
            });

            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

            try {
                loader.load(new URLRequest(url), new LoaderContext(true));
            } catch (e : Dynamic) {
                reject(Error.fromDynamic(Std.string(e)));
            }
        });
    }

    private function sendApiRequest(method : String) : Promise<DynamicExt> {
        // exceptions not handled
        return fetchJson('http://some.api/${method}').mapSuccessPromise(function(result : DynamicExt) : Promise<DynamicExt> {
            if (result["error"] != null) {
                return Promise.error(Error.fromDynamic(result["error"]));
            }

            return Promise.value(result);
        });
    }

    private function syncState() : Promise<Nil> {
        return sendApiRequest("sync-state").mapSuccessPromise(function(result : DynamicExt) : Promise<Nil> {
            var subPromises = new Array<Promise<Nil>>();
            Runner.updateStateFromTheResponse(result);

            if (result.exists("playerAvatarUrl")) {
                subPromises.push(fetchBitmapData(result["playerAvatarUrl"].asString()).mapSuccess(function(bmd : BitmapData) : Nil {
                    Runner.setPlayerAvatar(bmd);
                    return Nil.nil;
                }));
            }

            if (result.exists("opponentAvatarUrl")) {
                subPromises.push(fetchBitmapData(result["opponentAvatarUrl"].asString()).mapSuccess(function(bmd : BitmapData) : Nil {
                    Runner.setOpponentAvatar(bmd);
                    return Nil.nil;
                }));
            }

            return reallyAfterAll(subPromises);
        });
    }

    public function doTheTask() : Void {
        Runner.showLoader();

        syncState().then(function(result : Result<Nil, Error>) : Void {
            Runner.hideLoader();

            if (result.isSuccess) {
                Runner.onTaskSuccessed();
            } else {
                Runner.showErrorPopup();
            }
        });
    }

    private static function reallyAfterAll(arr : Array<Promise<Dynamic>>) : Promise<Nil> {
        return Promise.create(function(resolve, reject) {
            reallyAll(arr).either(
                function(_) { resolve(Nil.nil); },
                reject
            );
        });
    }

    private static function reallyAll<T>(arr : Array<Promise<T>>) : Promise<Array<T>> {
        if (arr.length == 0) {
            return Promise.value([]);
        }

        return Promise.create(function(resolve, reject) {
            var results = [];
            var counter = 0;
            var errors = [];

            arr.mapi(function(p, i) {
                p.either(function(value) {
                    if (errors.length == 0) {
                        results[i] = value;
                    }

                    counter++;

                    if (counter == arr.length) {
                        if (errors.length != 0) {
                            reject(Error.fromDynamic(errors));
                        } else {
                            resolve(results);
                        }
                    }
                }, function(err) {
                    errors.push(err);
                    counter++;

                    if (counter == arr.length) {
                        reject(Error.fromDynamic(errors));
                    }
                });
            });
        });
    }
}

#end
