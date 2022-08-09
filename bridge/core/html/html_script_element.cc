/*
 * Copyright (C) 2019-2022 The Kraken authors. All rights reserved.
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */
#include "html_script_element.h"
#include "html_names.h"

namespace kraken {

HTMLScriptElement::HTMLScriptElement(Document& document) : HTMLElement(html_names::kscript, &document) {}

}  // namespace kraken
