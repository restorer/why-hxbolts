package org.sample.fake;

class Variants {
    public static var urlLoaderVariant : URLLoaderVariant = URLLoaderVariant.None;
    public static var playerAvatarLoaderVariant : LoaderVariant = LoaderVariant.None;
    public static var opponentAvatarLoaderVariant : LoaderVariant = LoaderVariant.None;

    public static var loaderShown : Bool;
    public static var stateUpdated : Bool;
    public static var playerAvatarUpdated : Bool;
    public static var opponentAvatarUpdated : Bool;
    public static var everythingSuccessed : Bool;
    public static var errorPopupShown : Bool;

    public static function traceCondition() : Void {
        trace('${urlLoaderVariant} / ${playerAvatarLoaderVariant} / ${opponentAvatarLoaderVariant} ...');
    }

    public static function traceResult(status : String) : Void {
        trace('${status} : ${loaderShown} / ${stateUpdated} / ${playerAvatarUpdated} / ${opponentAvatarUpdated} / ${everythingSuccessed} / ${errorPopupShown}');
    }

    public static function next() : Bool {
        if (urlLoaderVariant == URLLoaderVariant.None
            || playerAvatarLoaderVariant == LoaderVariant.None
            || opponentAvatarLoaderVariant == LoaderVariant.None
        ) {
            urlLoaderVariant = URLLoaderVariant.First;
            playerAvatarLoaderVariant = LoaderVariant.First;
            opponentAvatarLoaderVariant = LoaderVariant.First;
        } else if (opponentAvatarLoaderVariant != LoaderVariant.Last) {
            opponentAvatarLoaderVariant = cast ((cast opponentAvatarLoaderVariant:Int) + 1);
        } else {
            opponentAvatarLoaderVariant = LoaderVariant.First;

            if (playerAvatarLoaderVariant != LoaderVariant.Last) {
                playerAvatarLoaderVariant = cast ((cast playerAvatarLoaderVariant:Int) + 1);
            } else {
                playerAvatarLoaderVariant = LoaderVariant.First;

                if (urlLoaderVariant == URLLoaderVariant.Last) {
                    return false;
                } else {
                    urlLoaderVariant = cast ((cast urlLoaderVariant:Int) + 1);
                }
            }
        }

        loaderShown = false;
        stateUpdated = false;
        playerAvatarUpdated = false;
        opponentAvatarUpdated = false;
        everythingSuccessed = false;
        errorPopupShown = false;

        return true;
    }

    public static function check() : Bool {
        var shouldStateUpdated = false;
        var shouldPlayerAvatarUpdated = false;
        var shouldOpponentAvatarUpdated = false;
        var shouldErrorPopupShown = false;

        var anyPlayerAvatarStatus = false;
        var anyOpponentAvatarStatus = false;

        var checkForPlayerAvatar = false;
        var checkForOpponentAvatar = false;

        switch (urlLoaderVariant) {
            case ResponseDataAndBothAvatars:
                shouldStateUpdated = true;
                checkForPlayerAvatar = true;
                checkForOpponentAvatar = true;

            case ResponseDataAndPlayerAvatar:
                shouldStateUpdated = true;
                checkForPlayerAvatar = true;

            case ResponseDataAndOpponentAvatar:
                shouldStateUpdated = true;
                checkForOpponentAvatar = true;

            case ResponseDataOnly:
                shouldStateUpdated = true;

            case ResponseError | DispatchIoError | DispatchSecurityError | ThrowError:
                shouldErrorPopupShown = true;

            case None:
                throw 'Shound never happen';
        }

        if (checkForPlayerAvatar) {
            switch (playerAvatarLoaderVariant) {
                case Response:
                    shouldPlayerAvatarUpdated = true;

                case DispatchIoError | DispatchSecurityError | ThrowError:
                    shouldErrorPopupShown = true;
                    anyOpponentAvatarStatus = true;

                case None:
                    throw 'Shound never happen';
            }
        }

        if (checkForOpponentAvatar) {
            switch (opponentAvatarLoaderVariant) {
                case Response:
                    shouldOpponentAvatarUpdated = true;

                case DispatchIoError | DispatchSecurityError | ThrowError:
                    shouldErrorPopupShown = true;
                    anyPlayerAvatarStatus = true;

                case None:
                    throw 'Shound never happen';
            }
        }

        if (loaderShown
            || stateUpdated != shouldStateUpdated
            || (!anyPlayerAvatarStatus && playerAvatarUpdated != shouldPlayerAvatarUpdated)
            || (!anyOpponentAvatarStatus && opponentAvatarUpdated != shouldOpponentAvatarUpdated)
            || everythingSuccessed != !shouldErrorPopupShown
            || errorPopupShown != shouldErrorPopupShown
        ) {
            traceResult("FAILURE");
            return false;
        } else {
            traceResult("OK");
            return true;
        }
    }
}
