package org.sample.fake;

@:enum
abstract LoaderVariant(Int) {
    var Response = 1;
    var DispatchIoError = 2;
    var DispatchSecurityError = 3;
    var ThrowError = 4;

    var None = 0;
    var First = 1;
    var Last = 4;
}
