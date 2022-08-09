/*
 * Copyright (C) 2019-2022 The Kraken authors. All rights reserved.
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */
#include "pending_promises.h"
#include "script_promise.h"

namespace kraken {

void PendingPromises::TrackPendingPromises(ScriptPromise&& promise) {
  promises_.emplace_back(promise);
}

}  // namespace kraken
