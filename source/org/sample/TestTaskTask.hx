package org.sample;

#if test_task

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import haxe.Json;
import haxe.Timer;
import haxe.ds.Either;
import org.sample.fake.Loader;
import org.sample.fake.LoaderContext;
import org.sample.fake.Runner;
import org.sample.fake.TestTask;
import org.sample.fake.URLLoader;
import org.sample.fake.URLLoaderDataFormat;
import org.sample.fake.URLRequest;
import org.zamedev.lib.DynamicExt;
import task.Task;
import task.TaskList;

using org.zamedev.lib.DynamicTools;
using StringTools;

class TestTaskTask implements TestTask {
    private var taskList : TaskList;

    public function new() : Void {
        trace("[ task ]");
    }

    private function fetchText(url : String) : Task {
        var task : Task = null;

        var handler = function(completeHandler : Dynamic) : Void {
            var urlLoader = new URLLoader();

            var onLoaderError = function(e : Event) : Void {
                task.result = Either.Left(e.type);
                completeHandler(true);
            };

            urlLoader.addEventListener(Event.COMPLETE, function(_) : Void {
                task.result = Either.Right(Std.string(urlLoader.data));
                completeHandler(true);
            });

            urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

            try {
                urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
                urlLoader.load(new URLRequest(url));
            } catch (e : Dynamic) {
                Timer.delay(function() : Void {
                    task.result = Either.Left(Std.string(e));
                    completeHandler(true);
                }, 0);
            }
        };

        task = new Task('fetchText:${url}', handler, [TaskList.handleEvent()]);
        taskList.addTask(task);

        return task;
    }

    private function fetchJson(url : String) : Task {
        var fetchTextTask = fetchText(url);

        var task = new Task('fetchJson:${url}', function() : Either<String, DynamicExt> {
            switch ((cast fetchTextTask.result : Either<String, String>)) {
                case Left(v):
                    return Either.Left(v);

                case Right(v):
                    try {
                        return Either.Right(Json.parse(v));
                    } catch (e : Dynamic) {
                        return Either.Left(Std.string(e));
                    }
            }
        });

        taskList.addTask(task, [fetchTextTask]);
        return task;
    }

    private function fetchBitmapData(url : String) : Task {
        var task : Task = null;

        var handler = function(completeHandler : Dynamic) : Void {
            var loader = new Loader();

            var onLoaderError = function(e : Event) : Void {
                task.result = Either.Left(e.type);
                completeHandler(true);
            };

            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(_) : Void {
                task.result = Either.Right((cast loader.content:Bitmap).bitmapData);
                completeHandler(true);
            });

            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);

            try {
                loader.load(new URLRequest(url), new LoaderContext(true));
            } catch (e : Dynamic) {
                Timer.delay(function() : Void {
                    task.result = Either.Left(Std.string(e));
                    completeHandler(true);
                }, 0);
            }
        };

        task = new Task('fetchBitmapData:${url}', handler, [TaskList.handleEvent()]);
        taskList.addTask(task);

        return task;
    }

    private function sendApiRequest(method : String) : Task {
        var fetchJsonTask = fetchJson('http://some.api/${method}');

        var task = new Task('sendApiRequest:${method}', function() : Either<String, DynamicExt> {
            switch ((cast fetchJsonTask.result : Either<String, DynamicExt>)) {
                case Left(v):
                    return Either.Left(v);

                case Right(v):
                    if (v["error"] != null) {
                        return Either.Left(v["error"].asString());
                    } else {
                        return Either.Right(v);
                    }
            }
        });

        taskList.addTask(task, [fetchJsonTask]);
        return task;
    }

    private function syncState() : Task {
        var task : Task = null;
        var sendApiRequestTask = sendApiRequest("sync-state");

        var handler = function(completeHandler : Dynamic) : Void {
            switch ((cast sendApiRequestTask.result : Either<String, DynamicExt>)) {
                case Left(v): {
                    Timer.delay(function() : Void {
                        task.result = false;
                        completeHandler(true);
                    }, 0);
                }

                case Right(v): {
                    Runner.updateStateFromTheResponse(v);

                    var taskResult = true;
                    var subTasks : Array<Task> = [];

                    if (v.exists("playerAvatarUrl")) {
                        var fetchBitmapDataTask = fetchBitmapData(v["playerAvatarUrl"].asString());

                        var subTask = new Task('setPlayerAvatar', function() : Void {
                            switch ((cast fetchBitmapDataTask.result : Either<String, BitmapData>)) {
                                case Left(v):
                                    taskResult = false;

                                case Right(v):
                                    Runner.setPlayerAvatar(v);
                            }
                        });

                        subTasks.push(subTask);
                        taskList.addTask(subTask, [fetchBitmapDataTask]);
                    }

                    if (v.exists("opponentAvatarUrl")) {
                        var fetchBitmapDataTask = fetchBitmapData(v["opponentAvatarUrl"].asString());

                        var subTask = new Task('setOpponentAvatar', function() : Void {
                            switch ((cast fetchBitmapDataTask.result : Either<String, BitmapData>)) {
                                case Left(v):
                                    taskResult = false;

                                case Right(v):
                                    Runner.setOpponentAvatar(v);
                            }
                        });

                        subTasks.push(subTask);
                        taskList.addTask(subTask, [fetchBitmapDataTask]);
                    }

                    taskList.addTask(new Task('syncState:sub', function() : Void {
                        task.result = taskResult;
                        completeHandler(true);
                    }), subTasks);
                }
            }
        };

        task = new Task('syncState', handler, [TaskList.handleEvent()]);
        taskList.addTask(task, [sendApiRequestTask]);

        return task;
    }

    public function doTheTask() : Void {
        taskList = new TaskList();

        Runner.showLoader();
        var syncStateTask = syncState();

        taskList.addTask(new Task('main', function() : Void {
            Runner.hideLoader();

            if ((cast syncStateTask.result : Bool)) {
                Runner.onTaskSuccessed();
            } else {
                Runner.showErrorPopup();
            }
        }), [syncStateTask]);
    }
}

#end
