package org.sample.fake;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import haxe.Timer;

class Loader {
    public var contentLoaderInfo : LoaderInfo = new LoaderInfo();
    public var content : Dynamic = null;

    public function new() : Void {
    }

    public function load(urlRequest : URLRequest, loaderContext : LoaderContext) : Void {
        var loaderVariant : LoaderVariant;

        if (urlRequest.url == "http://some.api/player.jpg") {
            loaderVariant = Variants.playerAvatarLoaderVariant;
        } else {
            loaderVariant = Variants.opponentAvatarLoaderVariant;
        }

        if (loaderVariant == LoaderVariant.ThrowError) {
            throw 'Example loader error';
        }

        Timer.delay(function() : Void {
            switch (loaderVariant) {
                case DispatchIoError:
                    contentLoaderInfo.dispatchEvent(new Event(IOErrorEvent.IO_ERROR));

                case DispatchSecurityError:
                    contentLoaderInfo.dispatchEvent(new Event(SecurityErrorEvent.SECURITY_ERROR));

                case Response:
                    content = new Bitmap();
                    (cast content:Bitmap).bitmapData = new BitmapData(1, 1, true, 0);
                    contentLoaderInfo.dispatchEvent(new Event(Event.COMPLETE));

                default:
            }
        }, Math.floor(Math.random() * 50) + 10);
    }
}
