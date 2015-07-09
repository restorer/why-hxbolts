package org.sample.fake;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import haxe.Timer;

class URLLoader extends EventDispatcher {
    public var dataFormat : URLLoaderDataFormat = null;
    public var data : Dynamic = null;

    public function new() : Void {
        super();
    }

    public function load(urlRequest : URLRequest) : Void {
        if (Variants.urlLoaderVariant == URLLoaderVariant.ThrowError) {
            throw 'Example error';
        }

        Timer.delay(function() : Void {
            switch (Variants.urlLoaderVariant) {
                case DispatchIoError:
                    dispatchEvent(new Event(IOErrorEvent.IO_ERROR));

                case DispatchSecurityError:
                    dispatchEvent(new Event(SecurityErrorEvent.SECURITY_ERROR));

                case ResponseDataAndBothAvatars:
                    data = "{\"data\":\"value\",\"playerAvatarUrl\":\"http://some.api/player.jpg\",\"opponentAvatarUrl\":\"http://some.api/opponent.jpg\"}";
                    dispatchEvent(new Event(Event.COMPLETE));

                case ResponseDataAndPlayerAvatar:
                    data = "{\"data\":\"value\",\"playerAvatarUrl\":\"http://some.api/player.jpg\"}";
                    dispatchEvent(new Event(Event.COMPLETE));

                case ResponseDataAndOpponentAvatar:
                    data = "{\"data\":\"value\",\"opponentAvatarUrl\":\"http://some.api/opponent.jpg\"}";
                    dispatchEvent(new Event(Event.COMPLETE));

                case ResponseDataOnly:
                    data = "{\"data\":\"value\"}";
                    dispatchEvent(new Event(Event.COMPLETE));

                case ResponseError:
                    data = "{\"error\":\"Example api error\"}";
                    dispatchEvent(new Event(Event.COMPLETE));

                default:
            }
        }, Math.floor(Math.random() * 50) + 10);
    }
}
