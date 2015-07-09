package org.sample.fake;

typedef OneVariant = {
    urlLoaderVariant : SyncStateResponseVariant,
    playerAvatarLoaderVariant : LoaderVariant,
    opponentAvatarLoaderVariant : LoaderVariant,
    stateUpdated : Bool,
    playerAvatarUpdated : Bool,
    opponentAvatarUpdated : Bool,
    everythingSuccessed : Bool,
    errorPopupShown : Bool,
};
