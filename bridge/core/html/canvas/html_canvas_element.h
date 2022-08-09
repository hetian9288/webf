/*
 * Copyright (C) 2019-2022 The Kraken authors. All rights reserved.
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */
#ifndef KRAKENBRIDGE_CORE_HTML_CANVAS_HTML_CANVAS_ELEMENT_H_
#define KRAKENBRIDGE_CORE_HTML_CANVAS_HTML_CANVAS_ELEMENT_H_

#include "core/html/html_element.h"

namespace kraken {

class HTMLCanvasElement : public HTMLElement {
 public:
  explicit HTMLCanvasElement(Document&);
};

}  // namespace kraken

#endif  // KRAKENBRIDGE_CORE_HTML_CANVAS_HTML_CANVAS_ELEMENT_H_
