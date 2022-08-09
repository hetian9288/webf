/*
 * Copyright (C) 2019-2022 The Kraken authors. All rights reserved.
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */

#include "html_div_element.h"
#include "html_names.h"

namespace kraken {

HTMLDivElement::HTMLDivElement(Document& document) : HTMLElement(html_names::kdiv, &document) {}

}  // namespace kraken
