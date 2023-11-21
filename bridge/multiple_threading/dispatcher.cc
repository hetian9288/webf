/*
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */

#include "dispatcher.h"

#include "foundation/logging.h"

using namespace webf;

namespace webf {

namespace multi_threading {

Dispatcher::Dispatcher(Dart_Port dart_port, bool dedicated_thread)
    : dart_port_(dart_port), dedicated_thread_(dedicated_thread) {
}

Dispatcher::~Dispatcher() {
  for(auto&& thread : js_threads_) {
    PostToJsSync(thread.first, [](Looper* looper) {
      looper->ExecuteOpaqueFinalizer();
    }, thread.second.get());
  }

  for(auto&& thread : js_threads_) {
    thread.second->Stop();
  }
}

void Dispatcher::AllocateNewJSThread(int32_t js_context_id) {
  assert(js_threads_.count(js_context_id) == 0);
  assert(dedicated_thread_);
  js_threads_[js_context_id] = std::make_unique<Looper>(js_context_id);
  js_threads_[js_context_id]->Start();
}

void Dispatcher::KillJSThread(int32_t js_context_id) {
  assert(js_threads_.count(js_context_id) == 0);
  assert(dedicated_thread_);
  auto& looper = js_threads_[js_context_id];
  looper->Stop();
  js_threads_.erase(js_context_id);
}

void Dispatcher::SetOpaqueForJSThread(int32_t js_context_id, void* opaque, OpaqueFinalizer finalizer) {
  assert(js_threads_.count(js_context_id) > 0);
  assert(dedicated_thread_);
  js_threads_[js_context_id]->SetOpaque(opaque, finalizer);
}

std::unique_ptr<Looper>& Dispatcher::looper(int32_t js_context_id) {
  assert(js_threads_.count(js_context_id) > 0);
  return js_threads_[js_context_id];
}

// run in the cpp thread
void Dispatcher::NotifyDart(const DartWork* work_ptr) {
  WEBF_LOG(VERBOSE) << "[CPP] Dispatcher::NotifyDart call from c++, dart_port= " << dart_port_ << std::endl;
  const intptr_t work_addr = reinterpret_cast<intptr_t>(work_ptr);

  Dart_CObject dart_object;
  dart_object.type = Dart_CObject_kInt64;
  dart_object.value.as_int64 = work_addr;

  const bool result = Dart_PostCObject_DL(dart_port_, &dart_object);
  if (!result) {
    WEBF_LOG(ERROR) << "[CPP] Dispatcher::NotifyDart failed" << std::endl;
    delete work_ptr;
  }
}

}  // namespace multi_threading

}  // namespace webf