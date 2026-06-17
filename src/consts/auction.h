#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* AUCTIONING STATES */
typedef enum {
    AUC_NULL_STATE    = 0,  /* not doing anything */
    AUC_OFFERING      = 1,  /* object has been offfered */
    AUC_GOING_ONCE    = 2,  /* object is going once! */
    AUC_GOING_TWICE   = 3,  /* object is going twice! */
    AUC_LAST_CALL     = 4,  /* last call for the object! */
    AUC_SOLD          = 5,
    /* AUCTION CANCEL STATES */
    AUC_NORMAL_CANCEL = 6,  /* normal cancellation of auction */
    AUC_QUIT_CANCEL   = 7,  /* auction canclled because player quit */
    AUC_WIZ_CANCEL    = 8,  /* auction cancelled by a god */
    /* OTHER JUNK */
    AUC_STAT          = 9,
    AUC_BID           = 10,
} AuctionState;

#ifdef __cplusplus
}
#endif
