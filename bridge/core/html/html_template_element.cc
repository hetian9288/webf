/*
 * Copyright (C) 2019-2022 The Kraken authors. All rights reserved.
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */
#include "html_template_element.h"
#include "core/dom/document_fragment.h"
#include "html_names.h"

namespace kraken {

HTMLTemplateElement::HTMLTemplateElement(Document& document) : HTMLElement(html_names::ktemplate, &document) {}

DocumentFragment* HTMLTemplateElement::content() const {
  return ContentInternal();
}

DocumentFragment* HTMLTemplateElement::ContentInternal() const {
  if (!content_ && GetExecutingContext())
    content_ = DocumentFragment::Create(GetDocument());

  return content_.Get();
}

}  // namespace kraken
