/*
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */

#ifndef MULTI_THREADING_DOUBULE_UI_COMMAND_H_
#define MULTI_THREADING_DOUBULE_UI_COMMAND_H_

#include "foundation/ui_command_buffer.h"

namespace webf {

class DoubleUICommand {
 public:
  DoubleUICommand(ExecutingContext* context);

  void addCommand(UICommand type,
                  std::unique_ptr<SharedNativeString>&& args_01,
                  void* nativePtr,
                  void* nativePtr2,
                  bool request_ui_update = true);

  UICommandItem* data();
  int64_t size();
  bool empty();
  void clear();

  UICommandBuffer* getFrontBuffer();
  void swapBuffers();

 private:
  std::unique_ptr<UICommandBuffer> frontBuffer = nullptr;
  std::unique_ptr<UICommandBuffer> backBuffer = nullptr;
  std::atomic<bool> isSwapping;
  ExecutingContext* context_;
};

}  // namespace webf

#endif  // MULTI_THREADING_DOUBULE_UI_COMMAND_H_