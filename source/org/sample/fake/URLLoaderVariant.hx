package org.sample.fake;

@:enum
abstract URLLoaderVariant(Int) {
    var ResponseDataAndBothAvatars = 1;
    var ResponseDataAndPlayerAvatar = 2;
    var ResponseDataAndOpponentAvatar = 3;
    var ResponseDataOnly = 4;
    var ResponseError = 5;
    var DispatchIoError = 6;
    var DispatchSecurityError = 7;
    var ThrowError = 8;

    var None = 0;
    var First = 1;
    var Last = 8;
}
