// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: Charge.proto

#ifndef GOOGLE_PROTOBUF_INCLUDED_Charge_2eproto
#define GOOGLE_PROTOBUF_INCLUDED_Charge_2eproto

#include <limits>
#include <string>

#include <google/protobuf/port_def.inc>
#if PROTOBUF_VERSION < 3020000
#error This file was generated by a newer version of protoc which is
#error incompatible with your Protocol Buffer headers. Please update
#error your headers.
#endif
#if 3020003 < PROTOBUF_MIN_PROTOC_VERSION
#error This file was generated by an older version of protoc which is
#error incompatible with your Protocol Buffer headers. Please
#error regenerate this file with a newer version of protoc.
#endif

#include <google/protobuf/port_undef.inc>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/arena.h>
#include <google/protobuf/arenastring.h>
#include <google/protobuf/generated_message_bases.h>
#include <google/protobuf/generated_message_util.h>
#include <google/protobuf/metadata_lite.h>
#include <google/protobuf/generated_message_reflection.h>
#include <google/protobuf/message.h>
#include <google/protobuf/repeated_field.h>  // IWYU pragma: export
#include <google/protobuf/extension_set.h>  // IWYU pragma: export
#include <google/protobuf/unknown_field_set.h>
// @@protoc_insertion_point(includes)
#include <google/protobuf/port_def.inc>
#define PROTOBUF_INTERNAL_EXPORT_Charge_2eproto
PROTOBUF_NAMESPACE_OPEN
namespace internal {
class AnyMetadata;
}  // namespace internal
PROTOBUF_NAMESPACE_CLOSE

// Internal implementation detail -- do not use these members.
struct TableStruct_Charge_2eproto {
  static const uint32_t offsets[];
};
extern const ::PROTOBUF_NAMESPACE_ID::internal::DescriptorTable descriptor_table_Charge_2eproto;
class ChargeData;
struct ChargeDataDefaultTypeInternal;
extern ChargeDataDefaultTypeInternal _ChargeData_default_instance_;
class NotifyRetCharge;
struct NotifyRetChargeDefaultTypeInternal;
extern NotifyRetChargeDefaultTypeInternal _NotifyRetCharge_default_instance_;
class ReqChargeInfo;
struct ReqChargeInfoDefaultTypeInternal;
extern ReqChargeInfoDefaultTypeInternal _ReqChargeInfo_default_instance_;
class ReqStartCharge;
struct ReqStartChargeDefaultTypeInternal;
extern ReqStartChargeDefaultTypeInternal _ReqStartCharge_default_instance_;
class ResChargeInfo;
struct ResChargeInfoDefaultTypeInternal;
extern ResChargeInfoDefaultTypeInternal _ResChargeInfo_default_instance_;
PROTOBUF_NAMESPACE_OPEN
template<> ::ChargeData* Arena::CreateMaybeMessage<::ChargeData>(Arena*);
template<> ::NotifyRetCharge* Arena::CreateMaybeMessage<::NotifyRetCharge>(Arena*);
template<> ::ReqChargeInfo* Arena::CreateMaybeMessage<::ReqChargeInfo>(Arena*);
template<> ::ReqStartCharge* Arena::CreateMaybeMessage<::ReqStartCharge>(Arena*);
template<> ::ResChargeInfo* Arena::CreateMaybeMessage<::ResChargeInfo>(Arena*);
PROTOBUF_NAMESPACE_CLOSE

// ===================================================================

class ReqChargeInfo final :
    public ::PROTOBUF_NAMESPACE_ID::internal::ZeroFieldsBase /* @@protoc_insertion_point(class_definition:ReqChargeInfo) */ {
 public:
  inline ReqChargeInfo() : ReqChargeInfo(nullptr) {}
  explicit PROTOBUF_CONSTEXPR ReqChargeInfo(::PROTOBUF_NAMESPACE_ID::internal::ConstantInitialized);

  ReqChargeInfo(const ReqChargeInfo& from);
  ReqChargeInfo(ReqChargeInfo&& from) noexcept
    : ReqChargeInfo() {
    *this = ::std::move(from);
  }

  inline ReqChargeInfo& operator=(const ReqChargeInfo& from) {
    CopyFrom(from);
    return *this;
  }
  inline ReqChargeInfo& operator=(ReqChargeInfo&& from) noexcept {
    if (this == &from) return *this;
    if (GetOwningArena() == from.GetOwningArena()
  #ifdef PROTOBUF_FORCE_COPY_IN_MOVE
        && GetOwningArena() != nullptr
  #endif  // !PROTOBUF_FORCE_COPY_IN_MOVE
    ) {
      InternalSwap(&from);
    } else {
      CopyFrom(from);
    }
    return *this;
  }

  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* descriptor() {
    return GetDescriptor();
  }
  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* GetDescriptor() {
    return default_instance().GetMetadata().descriptor;
  }
  static const ::PROTOBUF_NAMESPACE_ID::Reflection* GetReflection() {
    return default_instance().GetMetadata().reflection;
  }
  static const ReqChargeInfo& default_instance() {
    return *internal_default_instance();
  }
  static inline const ReqChargeInfo* internal_default_instance() {
    return reinterpret_cast<const ReqChargeInfo*>(
               &_ReqChargeInfo_default_instance_);
  }
  static constexpr int kIndexInFileMessages =
    0;

  friend void swap(ReqChargeInfo& a, ReqChargeInfo& b) {
    a.Swap(&b);
  }
  inline void Swap(ReqChargeInfo* other) {
    if (other == this) return;
  #ifdef PROTOBUF_FORCE_COPY_IN_SWAP
    if (GetOwningArena() != nullptr &&
        GetOwningArena() == other->GetOwningArena()) {
   #else  // PROTOBUF_FORCE_COPY_IN_SWAP
    if (GetOwningArena() == other->GetOwningArena()) {
  #endif  // !PROTOBUF_FORCE_COPY_IN_SWAP
      InternalSwap(other);
    } else {
      ::PROTOBUF_NAMESPACE_ID::internal::GenericSwap(this, other);
    }
  }
  void UnsafeArenaSwap(ReqChargeInfo* other) {
    if (other == this) return;
    GOOGLE_DCHECK(GetOwningArena() == other->GetOwningArena());
    InternalSwap(other);
  }

  // implements Message ----------------------------------------------

  ReqChargeInfo* New(::PROTOBUF_NAMESPACE_ID::Arena* arena = nullptr) const final {
    return CreateMaybeMessage<ReqChargeInfo>(arena);
  }
  using ::PROTOBUF_NAMESPACE_ID::internal::ZeroFieldsBase::CopyFrom;
  inline void CopyFrom(const ReqChargeInfo& from) {
    ::PROTOBUF_NAMESPACE_ID::internal::ZeroFieldsBase::CopyImpl(this, from);
  }
  using ::PROTOBUF_NAMESPACE_ID::internal::ZeroFieldsBase::MergeFrom;
  void MergeFrom(const ReqChargeInfo& from) {
    ::PROTOBUF_NAMESPACE_ID::internal::ZeroFieldsBase::MergeImpl(this, from);
  }
  public:

  private:
  friend class ::PROTOBUF_NAMESPACE_ID::internal::AnyMetadata;
  static ::PROTOBUF_NAMESPACE_ID::StringPiece FullMessageName() {
    return "ReqChargeInfo";
  }
  protected:
  explicit ReqChargeInfo(::PROTOBUF_NAMESPACE_ID::Arena* arena,
                       bool is_message_owned = false);
  public:

  static const ClassData _class_data_;
  const ::PROTOBUF_NAMESPACE_ID::Message::ClassData*GetClassData() const final;

  ::PROTOBUF_NAMESPACE_ID::Metadata GetMetadata() const final;

  // nested types ----------------------------------------------------

  // accessors -------------------------------------------------------

  // @@protoc_insertion_point(class_scope:ReqChargeInfo)
 private:
  class _Internal;

  template <typename T> friend class ::PROTOBUF_NAMESPACE_ID::Arena::InternalHelper;
  typedef void InternalArenaConstructable_;
  typedef void DestructorSkippable_;
  friend struct ::TableStruct_Charge_2eproto;
};
// -------------------------------------------------------------------

class ChargeData final :
    public ::PROTOBUF_NAMESPACE_ID::Message /* @@protoc_insertion_point(class_definition:ChargeData) */ {
 public:
  inline ChargeData() : ChargeData(nullptr) {}
  ~ChargeData() override;
  explicit PROTOBUF_CONSTEXPR ChargeData(::PROTOBUF_NAMESPACE_ID::internal::ConstantInitialized);

  ChargeData(const ChargeData& from);
  ChargeData(ChargeData&& from) noexcept
    : ChargeData() {
    *this = ::std::move(from);
  }

  inline ChargeData& operator=(const ChargeData& from) {
    CopyFrom(from);
    return *this;
  }
  inline ChargeData& operator=(ChargeData&& from) noexcept {
    if (this == &from) return *this;
    if (GetOwningArena() == from.GetOwningArena()
  #ifdef PROTOBUF_FORCE_COPY_IN_MOVE
        && GetOwningArena() != nullptr
  #endif  // !PROTOBUF_FORCE_COPY_IN_MOVE
    ) {
      InternalSwap(&from);
    } else {
      CopyFrom(from);
    }
    return *this;
  }

  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* descriptor() {
    return GetDescriptor();
  }
  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* GetDescriptor() {
    return default_instance().GetMetadata().descriptor;
  }
  static const ::PROTOBUF_NAMESPACE_ID::Reflection* GetReflection() {
    return default_instance().GetMetadata().reflection;
  }
  static const ChargeData& default_instance() {
    return *internal_default_instance();
  }
  static inline const ChargeData* internal_default_instance() {
    return reinterpret_cast<const ChargeData*>(
               &_ChargeData_default_instance_);
  }
  static constexpr int kIndexInFileMessages =
    1;

  friend void swap(ChargeData& a, ChargeData& b) {
    a.Swap(&b);
  }
  inline void Swap(ChargeData* other) {
    if (other == this) return;
  #ifdef PROTOBUF_FORCE_COPY_IN_SWAP
    if (GetOwningArena() != nullptr &&
        GetOwningArena() == other->GetOwningArena()) {
   #else  // PROTOBUF_FORCE_COPY_IN_SWAP
    if (GetOwningArena() == other->GetOwningArena()) {
  #endif  // !PROTOBUF_FORCE_COPY_IN_SWAP
      InternalSwap(other);
    } else {
      ::PROTOBUF_NAMESPACE_ID::internal::GenericSwap(this, other);
    }
  }
  void UnsafeArenaSwap(ChargeData* other) {
    if (other == this) return;
    GOOGLE_DCHECK(GetOwningArena() == other->GetOwningArena());
    InternalSwap(other);
  }

  // implements Message ----------------------------------------------

  ChargeData* New(::PROTOBUF_NAMESPACE_ID::Arena* arena = nullptr) const final {
    return CreateMaybeMessage<ChargeData>(arena);
  }
  using ::PROTOBUF_NAMESPACE_ID::Message::CopyFrom;
  void CopyFrom(const ChargeData& from);
  using ::PROTOBUF_NAMESPACE_ID::Message::MergeFrom;
  void MergeFrom(const ChargeData& from);
  private:
  static void MergeImpl(::PROTOBUF_NAMESPACE_ID::Message* to, const ::PROTOBUF_NAMESPACE_ID::Message& from);
  public:
  PROTOBUF_ATTRIBUTE_REINITIALIZES void Clear() final;
  bool IsInitialized() const final;

  size_t ByteSizeLong() const final;
  const char* _InternalParse(const char* ptr, ::PROTOBUF_NAMESPACE_ID::internal::ParseContext* ctx) final;
  uint8_t* _InternalSerialize(
      uint8_t* target, ::PROTOBUF_NAMESPACE_ID::io::EpsCopyOutputStream* stream) const final;
  int GetCachedSize() const final { return _cached_size_.Get(); }

  private:
  void SharedCtor();
  void SharedDtor();
  void SetCachedSize(int size) const final;
  void InternalSwap(ChargeData* other);

  private:
  friend class ::PROTOBUF_NAMESPACE_ID::internal::AnyMetadata;
  static ::PROTOBUF_NAMESPACE_ID::StringPiece FullMessageName() {
    return "ChargeData";
  }
  protected:
  explicit ChargeData(::PROTOBUF_NAMESPACE_ID::Arena* arena,
                       bool is_message_owned = false);
  public:

  static const ClassData _class_data_;
  const ::PROTOBUF_NAMESPACE_ID::Message::ClassData*GetClassData() const final;

  ::PROTOBUF_NAMESPACE_ID::Metadata GetMetadata() const final;

  // nested types ----------------------------------------------------

  // accessors -------------------------------------------------------

  enum : int {
    kChargeIdFieldNumber = 1,
    kStatusFieldNumber = 2,
  };
  // int32 chargeId = 1;
  void clear_chargeid();
  int32_t chargeid() const;
  void set_chargeid(int32_t value);
  private:
  int32_t _internal_chargeid() const;
  void _internal_set_chargeid(int32_t value);
  public:

  // int32 status = 2;
  void clear_status();
  int32_t status() const;
  void set_status(int32_t value);
  private:
  int32_t _internal_status() const;
  void _internal_set_status(int32_t value);
  public:

  // @@protoc_insertion_point(class_scope:ChargeData)
 private:
  class _Internal;

  template <typename T> friend class ::PROTOBUF_NAMESPACE_ID::Arena::InternalHelper;
  typedef void InternalArenaConstructable_;
  typedef void DestructorSkippable_;
  int32_t chargeid_;
  int32_t status_;
  mutable ::PROTOBUF_NAMESPACE_ID::internal::CachedSize _cached_size_;
  friend struct ::TableStruct_Charge_2eproto;
};
// -------------------------------------------------------------------

class ResChargeInfo final :
    public ::PROTOBUF_NAMESPACE_ID::Message /* @@protoc_insertion_point(class_definition:ResChargeInfo) */ {
 public:
  inline ResChargeInfo() : ResChargeInfo(nullptr) {}
  ~ResChargeInfo() override;
  explicit PROTOBUF_CONSTEXPR ResChargeInfo(::PROTOBUF_NAMESPACE_ID::internal::ConstantInitialized);

  ResChargeInfo(const ResChargeInfo& from);
  ResChargeInfo(ResChargeInfo&& from) noexcept
    : ResChargeInfo() {
    *this = ::std::move(from);
  }

  inline ResChargeInfo& operator=(const ResChargeInfo& from) {
    CopyFrom(from);
    return *this;
  }
  inline ResChargeInfo& operator=(ResChargeInfo&& from) noexcept {
    if (this == &from) return *this;
    if (GetOwningArena() == from.GetOwningArena()
  #ifdef PROTOBUF_FORCE_COPY_IN_MOVE
        && GetOwningArena() != nullptr
  #endif  // !PROTOBUF_FORCE_COPY_IN_MOVE
    ) {
      InternalSwap(&from);
    } else {
      CopyFrom(from);
    }
    return *this;
  }

  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* descriptor() {
    return GetDescriptor();
  }
  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* GetDescriptor() {
    return default_instance().GetMetadata().descriptor;
  }
  static const ::PROTOBUF_NAMESPACE_ID::Reflection* GetReflection() {
    return default_instance().GetMetadata().reflection;
  }
  static const ResChargeInfo& default_instance() {
    return *internal_default_instance();
  }
  static inline const ResChargeInfo* internal_default_instance() {
    return reinterpret_cast<const ResChargeInfo*>(
               &_ResChargeInfo_default_instance_);
  }
  static constexpr int kIndexInFileMessages =
    2;

  friend void swap(ResChargeInfo& a, ResChargeInfo& b) {
    a.Swap(&b);
  }
  inline void Swap(ResChargeInfo* other) {
    if (other == this) return;
  #ifdef PROTOBUF_FORCE_COPY_IN_SWAP
    if (GetOwningArena() != nullptr &&
        GetOwningArena() == other->GetOwningArena()) {
   #else  // PROTOBUF_FORCE_COPY_IN_SWAP
    if (GetOwningArena() == other->GetOwningArena()) {
  #endif  // !PROTOBUF_FORCE_COPY_IN_SWAP
      InternalSwap(other);
    } else {
      ::PROTOBUF_NAMESPACE_ID::internal::GenericSwap(this, other);
    }
  }
  void UnsafeArenaSwap(ResChargeInfo* other) {
    if (other == this) return;
    GOOGLE_DCHECK(GetOwningArena() == other->GetOwningArena());
    InternalSwap(other);
  }

  // implements Message ----------------------------------------------

  ResChargeInfo* New(::PROTOBUF_NAMESPACE_ID::Arena* arena = nullptr) const final {
    return CreateMaybeMessage<ResChargeInfo>(arena);
  }
  using ::PROTOBUF_NAMESPACE_ID::Message::CopyFrom;
  void CopyFrom(const ResChargeInfo& from);
  using ::PROTOBUF_NAMESPACE_ID::Message::MergeFrom;
  void MergeFrom(const ResChargeInfo& from);
  private:
  static void MergeImpl(::PROTOBUF_NAMESPACE_ID::Message* to, const ::PROTOBUF_NAMESPACE_ID::Message& from);
  public:
  PROTOBUF_ATTRIBUTE_REINITIALIZES void Clear() final;
  bool IsInitialized() const final;

  size_t ByteSizeLong() const final;
  const char* _InternalParse(const char* ptr, ::PROTOBUF_NAMESPACE_ID::internal::ParseContext* ctx) final;
  uint8_t* _InternalSerialize(
      uint8_t* target, ::PROTOBUF_NAMESPACE_ID::io::EpsCopyOutputStream* stream) const final;
  int GetCachedSize() const final { return _cached_size_.Get(); }

  private:
  void SharedCtor();
  void SharedDtor();
  void SetCachedSize(int size) const final;
  void InternalSwap(ResChargeInfo* other);

  private:
  friend class ::PROTOBUF_NAMESPACE_ID::internal::AnyMetadata;
  static ::PROTOBUF_NAMESPACE_ID::StringPiece FullMessageName() {
    return "ResChargeInfo";
  }
  protected:
  explicit ResChargeInfo(::PROTOBUF_NAMESPACE_ID::Arena* arena,
                       bool is_message_owned = false);
  public:

  static const ClassData _class_data_;
  const ::PROTOBUF_NAMESPACE_ID::Message::ClassData*GetClassData() const final;

  ::PROTOBUF_NAMESPACE_ID::Metadata GetMetadata() const final;

  // nested types ----------------------------------------------------

  // accessors -------------------------------------------------------

  enum : int {
    kDataFieldNumber = 1,
  };
  // repeated .ChargeData data = 1;
  int data_size() const;
  private:
  int _internal_data_size() const;
  public:
  void clear_data();
  ::ChargeData* mutable_data(int index);
  ::PROTOBUF_NAMESPACE_ID::RepeatedPtrField< ::ChargeData >*
      mutable_data();
  private:
  const ::ChargeData& _internal_data(int index) const;
  ::ChargeData* _internal_add_data();
  public:
  const ::ChargeData& data(int index) const;
  ::ChargeData* add_data();
  const ::PROTOBUF_NAMESPACE_ID::RepeatedPtrField< ::ChargeData >&
      data() const;

  // @@protoc_insertion_point(class_scope:ResChargeInfo)
 private:
  class _Internal;

  template <typename T> friend class ::PROTOBUF_NAMESPACE_ID::Arena::InternalHelper;
  typedef void InternalArenaConstructable_;
  typedef void DestructorSkippable_;
  ::PROTOBUF_NAMESPACE_ID::RepeatedPtrField< ::ChargeData > data_;
  mutable ::PROTOBUF_NAMESPACE_ID::internal::CachedSize _cached_size_;
  friend struct ::TableStruct_Charge_2eproto;
};
// -------------------------------------------------------------------

class NotifyRetCharge final :
    public ::PROTOBUF_NAMESPACE_ID::Message /* @@protoc_insertion_point(class_definition:NotifyRetCharge) */ {
 public:
  inline NotifyRetCharge() : NotifyRetCharge(nullptr) {}
  ~NotifyRetCharge() override;
  explicit PROTOBUF_CONSTEXPR NotifyRetCharge(::PROTOBUF_NAMESPACE_ID::internal::ConstantInitialized);

  NotifyRetCharge(const NotifyRetCharge& from);
  NotifyRetCharge(NotifyRetCharge&& from) noexcept
    : NotifyRetCharge() {
    *this = ::std::move(from);
  }

  inline NotifyRetCharge& operator=(const NotifyRetCharge& from) {
    CopyFrom(from);
    return *this;
  }
  inline NotifyRetCharge& operator=(NotifyRetCharge&& from) noexcept {
    if (this == &from) return *this;
    if (GetOwningArena() == from.GetOwningArena()
  #ifdef PROTOBUF_FORCE_COPY_IN_MOVE
        && GetOwningArena() != nullptr
  #endif  // !PROTOBUF_FORCE_COPY_IN_MOVE
    ) {
      InternalSwap(&from);
    } else {
      CopyFrom(from);
    }
    return *this;
  }

  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* descriptor() {
    return GetDescriptor();
  }
  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* GetDescriptor() {
    return default_instance().GetMetadata().descriptor;
  }
  static const ::PROTOBUF_NAMESPACE_ID::Reflection* GetReflection() {
    return default_instance().GetMetadata().reflection;
  }
  static const NotifyRetCharge& default_instance() {
    return *internal_default_instance();
  }
  static inline const NotifyRetCharge* internal_default_instance() {
    return reinterpret_cast<const NotifyRetCharge*>(
               &_NotifyRetCharge_default_instance_);
  }
  static constexpr int kIndexInFileMessages =
    3;

  friend void swap(NotifyRetCharge& a, NotifyRetCharge& b) {
    a.Swap(&b);
  }
  inline void Swap(NotifyRetCharge* other) {
    if (other == this) return;
  #ifdef PROTOBUF_FORCE_COPY_IN_SWAP
    if (GetOwningArena() != nullptr &&
        GetOwningArena() == other->GetOwningArena()) {
   #else  // PROTOBUF_FORCE_COPY_IN_SWAP
    if (GetOwningArena() == other->GetOwningArena()) {
  #endif  // !PROTOBUF_FORCE_COPY_IN_SWAP
      InternalSwap(other);
    } else {
      ::PROTOBUF_NAMESPACE_ID::internal::GenericSwap(this, other);
    }
  }
  void UnsafeArenaSwap(NotifyRetCharge* other) {
    if (other == this) return;
    GOOGLE_DCHECK(GetOwningArena() == other->GetOwningArena());
    InternalSwap(other);
  }

  // implements Message ----------------------------------------------

  NotifyRetCharge* New(::PROTOBUF_NAMESPACE_ID::Arena* arena = nullptr) const final {
    return CreateMaybeMessage<NotifyRetCharge>(arena);
  }
  using ::PROTOBUF_NAMESPACE_ID::Message::CopyFrom;
  void CopyFrom(const NotifyRetCharge& from);
  using ::PROTOBUF_NAMESPACE_ID::Message::MergeFrom;
  void MergeFrom(const NotifyRetCharge& from);
  private:
  static void MergeImpl(::PROTOBUF_NAMESPACE_ID::Message* to, const ::PROTOBUF_NAMESPACE_ID::Message& from);
  public:
  PROTOBUF_ATTRIBUTE_REINITIALIZES void Clear() final;
  bool IsInitialized() const final;

  size_t ByteSizeLong() const final;
  const char* _InternalParse(const char* ptr, ::PROTOBUF_NAMESPACE_ID::internal::ParseContext* ctx) final;
  uint8_t* _InternalSerialize(
      uint8_t* target, ::PROTOBUF_NAMESPACE_ID::io::EpsCopyOutputStream* stream) const final;
  int GetCachedSize() const final { return _cached_size_.Get(); }

  private:
  void SharedCtor();
  void SharedDtor();
  void SetCachedSize(int size) const final;
  void InternalSwap(NotifyRetCharge* other);

  private:
  friend class ::PROTOBUF_NAMESPACE_ID::internal::AnyMetadata;
  static ::PROTOBUF_NAMESPACE_ID::StringPiece FullMessageName() {
    return "NotifyRetCharge";
  }
  protected:
  explicit NotifyRetCharge(::PROTOBUF_NAMESPACE_ID::Arena* arena,
                       bool is_message_owned = false);
  public:

  static const ClassData _class_data_;
  const ::PROTOBUF_NAMESPACE_ID::Message::ClassData*GetClassData() const final;

  ::PROTOBUF_NAMESPACE_ID::Metadata GetMetadata() const final;

  // nested types ----------------------------------------------------

  // accessors -------------------------------------------------------

  enum : int {
    kChargeIdFieldNumber = 1,
  };
  // int32 chargeId = 1;
  void clear_chargeid();
  int32_t chargeid() const;
  void set_chargeid(int32_t value);
  private:
  int32_t _internal_chargeid() const;
  void _internal_set_chargeid(int32_t value);
  public:

  // @@protoc_insertion_point(class_scope:NotifyRetCharge)
 private:
  class _Internal;

  template <typename T> friend class ::PROTOBUF_NAMESPACE_ID::Arena::InternalHelper;
  typedef void InternalArenaConstructable_;
  typedef void DestructorSkippable_;
  int32_t chargeid_;
  mutable ::PROTOBUF_NAMESPACE_ID::internal::CachedSize _cached_size_;
  friend struct ::TableStruct_Charge_2eproto;
};
// -------------------------------------------------------------------

class ReqStartCharge final :
    public ::PROTOBUF_NAMESPACE_ID::Message /* @@protoc_insertion_point(class_definition:ReqStartCharge) */ {
 public:
  inline ReqStartCharge() : ReqStartCharge(nullptr) {}
  ~ReqStartCharge() override;
  explicit PROTOBUF_CONSTEXPR ReqStartCharge(::PROTOBUF_NAMESPACE_ID::internal::ConstantInitialized);

  ReqStartCharge(const ReqStartCharge& from);
  ReqStartCharge(ReqStartCharge&& from) noexcept
    : ReqStartCharge() {
    *this = ::std::move(from);
  }

  inline ReqStartCharge& operator=(const ReqStartCharge& from) {
    CopyFrom(from);
    return *this;
  }
  inline ReqStartCharge& operator=(ReqStartCharge&& from) noexcept {
    if (this == &from) return *this;
    if (GetOwningArena() == from.GetOwningArena()
  #ifdef PROTOBUF_FORCE_COPY_IN_MOVE
        && GetOwningArena() != nullptr
  #endif  // !PROTOBUF_FORCE_COPY_IN_MOVE
    ) {
      InternalSwap(&from);
    } else {
      CopyFrom(from);
    }
    return *this;
  }

  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* descriptor() {
    return GetDescriptor();
  }
  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* GetDescriptor() {
    return default_instance().GetMetadata().descriptor;
  }
  static const ::PROTOBUF_NAMESPACE_ID::Reflection* GetReflection() {
    return default_instance().GetMetadata().reflection;
  }
  static const ReqStartCharge& default_instance() {
    return *internal_default_instance();
  }
  static inline const ReqStartCharge* internal_default_instance() {
    return reinterpret_cast<const ReqStartCharge*>(
               &_ReqStartCharge_default_instance_);
  }
  static constexpr int kIndexInFileMessages =
    4;

  friend void swap(ReqStartCharge& a, ReqStartCharge& b) {
    a.Swap(&b);
  }
  inline void Swap(ReqStartCharge* other) {
    if (other == this) return;
  #ifdef PROTOBUF_FORCE_COPY_IN_SWAP
    if (GetOwningArena() != nullptr &&
        GetOwningArena() == other->GetOwningArena()) {
   #else  // PROTOBUF_FORCE_COPY_IN_SWAP
    if (GetOwningArena() == other->GetOwningArena()) {
  #endif  // !PROTOBUF_FORCE_COPY_IN_SWAP
      InternalSwap(other);
    } else {
      ::PROTOBUF_NAMESPACE_ID::internal::GenericSwap(this, other);
    }
  }
  void UnsafeArenaSwap(ReqStartCharge* other) {
    if (other == this) return;
    GOOGLE_DCHECK(GetOwningArena() == other->GetOwningArena());
    InternalSwap(other);
  }

  // implements Message ----------------------------------------------

  ReqStartCharge* New(::PROTOBUF_NAMESPACE_ID::Arena* arena = nullptr) const final {
    return CreateMaybeMessage<ReqStartCharge>(arena);
  }
  using ::PROTOBUF_NAMESPACE_ID::Message::CopyFrom;
  void CopyFrom(const ReqStartCharge& from);
  using ::PROTOBUF_NAMESPACE_ID::Message::MergeFrom;
  void MergeFrom(const ReqStartCharge& from);
  private:
  static void MergeImpl(::PROTOBUF_NAMESPACE_ID::Message* to, const ::PROTOBUF_NAMESPACE_ID::Message& from);
  public:
  PROTOBUF_ATTRIBUTE_REINITIALIZES void Clear() final;
  bool IsInitialized() const final;

  size_t ByteSizeLong() const final;
  const char* _InternalParse(const char* ptr, ::PROTOBUF_NAMESPACE_ID::internal::ParseContext* ctx) final;
  uint8_t* _InternalSerialize(
      uint8_t* target, ::PROTOBUF_NAMESPACE_ID::io::EpsCopyOutputStream* stream) const final;
  int GetCachedSize() const final { return _cached_size_.Get(); }

  private:
  void SharedCtor();
  void SharedDtor();
  void SetCachedSize(int size) const final;
  void InternalSwap(ReqStartCharge* other);

  private:
  friend class ::PROTOBUF_NAMESPACE_ID::internal::AnyMetadata;
  static ::PROTOBUF_NAMESPACE_ID::StringPiece FullMessageName() {
    return "ReqStartCharge";
  }
  protected:
  explicit ReqStartCharge(::PROTOBUF_NAMESPACE_ID::Arena* arena,
                       bool is_message_owned = false);
  public:

  static const ClassData _class_data_;
  const ::PROTOBUF_NAMESPACE_ID::Message::ClassData*GetClassData() const final;

  ::PROTOBUF_NAMESPACE_ID::Metadata GetMetadata() const final;

  // nested types ----------------------------------------------------

  // accessors -------------------------------------------------------

  enum : int {
    kExtraFieldNumber = 3,
    kChargeIdFieldNumber = 1,
    kMoneyFieldNumber = 2,
  };
  // string extra = 3;
  void clear_extra();
  const std::string& extra() const;
  template <typename ArgT0 = const std::string&, typename... ArgT>
  void set_extra(ArgT0&& arg0, ArgT... args);
  std::string* mutable_extra();
  PROTOBUF_NODISCARD std::string* release_extra();
  void set_allocated_extra(std::string* extra);
  private:
  const std::string& _internal_extra() const;
  inline PROTOBUF_ALWAYS_INLINE void _internal_set_extra(const std::string& value);
  std::string* _internal_mutable_extra();
  public:

  // int32 chargeId = 1;
  void clear_chargeid();
  int32_t chargeid() const;
  void set_chargeid(int32_t value);
  private:
  int32_t _internal_chargeid() const;
  void _internal_set_chargeid(int32_t value);
  public:

  // int32 money = 2;
  void clear_money();
  int32_t money() const;
  void set_money(int32_t value);
  private:
  int32_t _internal_money() const;
  void _internal_set_money(int32_t value);
  public:

  // @@protoc_insertion_point(class_scope:ReqStartCharge)
 private:
  class _Internal;

  template <typename T> friend class ::PROTOBUF_NAMESPACE_ID::Arena::InternalHelper;
  typedef void InternalArenaConstructable_;
  typedef void DestructorSkippable_;
  ::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr extra_;
  int32_t chargeid_;
  int32_t money_;
  mutable ::PROTOBUF_NAMESPACE_ID::internal::CachedSize _cached_size_;
  friend struct ::TableStruct_Charge_2eproto;
};
// ===================================================================


// ===================================================================

#ifdef __GNUC__
  #pragma GCC diagnostic push
  #pragma GCC diagnostic ignored "-Wstrict-aliasing"
#endif  // __GNUC__
// ReqChargeInfo

// -------------------------------------------------------------------

// ChargeData

// int32 chargeId = 1;
inline void ChargeData::clear_chargeid() {
  chargeid_ = 0;
}
inline int32_t ChargeData::_internal_chargeid() const {
  return chargeid_;
}
inline int32_t ChargeData::chargeid() const {
  // @@protoc_insertion_point(field_get:ChargeData.chargeId)
  return _internal_chargeid();
}
inline void ChargeData::_internal_set_chargeid(int32_t value) {
  
  chargeid_ = value;
}
inline void ChargeData::set_chargeid(int32_t value) {
  _internal_set_chargeid(value);
  // @@protoc_insertion_point(field_set:ChargeData.chargeId)
}

// int32 status = 2;
inline void ChargeData::clear_status() {
  status_ = 0;
}
inline int32_t ChargeData::_internal_status() const {
  return status_;
}
inline int32_t ChargeData::status() const {
  // @@protoc_insertion_point(field_get:ChargeData.status)
  return _internal_status();
}
inline void ChargeData::_internal_set_status(int32_t value) {
  
  status_ = value;
}
inline void ChargeData::set_status(int32_t value) {
  _internal_set_status(value);
  // @@protoc_insertion_point(field_set:ChargeData.status)
}

// -------------------------------------------------------------------

// ResChargeInfo

// repeated .ChargeData data = 1;
inline int ResChargeInfo::_internal_data_size() const {
  return data_.size();
}
inline int ResChargeInfo::data_size() const {
  return _internal_data_size();
}
inline void ResChargeInfo::clear_data() {
  data_.Clear();
}
inline ::ChargeData* ResChargeInfo::mutable_data(int index) {
  // @@protoc_insertion_point(field_mutable:ResChargeInfo.data)
  return data_.Mutable(index);
}
inline ::PROTOBUF_NAMESPACE_ID::RepeatedPtrField< ::ChargeData >*
ResChargeInfo::mutable_data() {
  // @@protoc_insertion_point(field_mutable_list:ResChargeInfo.data)
  return &data_;
}
inline const ::ChargeData& ResChargeInfo::_internal_data(int index) const {
  return data_.Get(index);
}
inline const ::ChargeData& ResChargeInfo::data(int index) const {
  // @@protoc_insertion_point(field_get:ResChargeInfo.data)
  return _internal_data(index);
}
inline ::ChargeData* ResChargeInfo::_internal_add_data() {
  return data_.Add();
}
inline ::ChargeData* ResChargeInfo::add_data() {
  ::ChargeData* _add = _internal_add_data();
  // @@protoc_insertion_point(field_add:ResChargeInfo.data)
  return _add;
}
inline const ::PROTOBUF_NAMESPACE_ID::RepeatedPtrField< ::ChargeData >&
ResChargeInfo::data() const {
  // @@protoc_insertion_point(field_list:ResChargeInfo.data)
  return data_;
}

// -------------------------------------------------------------------

// NotifyRetCharge

// int32 chargeId = 1;
inline void NotifyRetCharge::clear_chargeid() {
  chargeid_ = 0;
}
inline int32_t NotifyRetCharge::_internal_chargeid() const {
  return chargeid_;
}
inline int32_t NotifyRetCharge::chargeid() const {
  // @@protoc_insertion_point(field_get:NotifyRetCharge.chargeId)
  return _internal_chargeid();
}
inline void NotifyRetCharge::_internal_set_chargeid(int32_t value) {
  
  chargeid_ = value;
}
inline void NotifyRetCharge::set_chargeid(int32_t value) {
  _internal_set_chargeid(value);
  // @@protoc_insertion_point(field_set:NotifyRetCharge.chargeId)
}

// -------------------------------------------------------------------

// ReqStartCharge

// int32 chargeId = 1;
inline void ReqStartCharge::clear_chargeid() {
  chargeid_ = 0;
}
inline int32_t ReqStartCharge::_internal_chargeid() const {
  return chargeid_;
}
inline int32_t ReqStartCharge::chargeid() const {
  // @@protoc_insertion_point(field_get:ReqStartCharge.chargeId)
  return _internal_chargeid();
}
inline void ReqStartCharge::_internal_set_chargeid(int32_t value) {
  
  chargeid_ = value;
}
inline void ReqStartCharge::set_chargeid(int32_t value) {
  _internal_set_chargeid(value);
  // @@protoc_insertion_point(field_set:ReqStartCharge.chargeId)
}

// int32 money = 2;
inline void ReqStartCharge::clear_money() {
  money_ = 0;
}
inline int32_t ReqStartCharge::_internal_money() const {
  return money_;
}
inline int32_t ReqStartCharge::money() const {
  // @@protoc_insertion_point(field_get:ReqStartCharge.money)
  return _internal_money();
}
inline void ReqStartCharge::_internal_set_money(int32_t value) {
  
  money_ = value;
}
inline void ReqStartCharge::set_money(int32_t value) {
  _internal_set_money(value);
  // @@protoc_insertion_point(field_set:ReqStartCharge.money)
}

// string extra = 3;
inline void ReqStartCharge::clear_extra() {
  extra_.ClearToEmpty();
}
inline const std::string& ReqStartCharge::extra() const {
  // @@protoc_insertion_point(field_get:ReqStartCharge.extra)
  return _internal_extra();
}
template <typename ArgT0, typename... ArgT>
inline PROTOBUF_ALWAYS_INLINE
void ReqStartCharge::set_extra(ArgT0&& arg0, ArgT... args) {
 
 extra_.Set(static_cast<ArgT0 &&>(arg0), args..., GetArenaForAllocation());
  // @@protoc_insertion_point(field_set:ReqStartCharge.extra)
}
inline std::string* ReqStartCharge::mutable_extra() {
  std::string* _s = _internal_mutable_extra();
  // @@protoc_insertion_point(field_mutable:ReqStartCharge.extra)
  return _s;
}
inline const std::string& ReqStartCharge::_internal_extra() const {
  return extra_.Get();
}
inline void ReqStartCharge::_internal_set_extra(const std::string& value) {
  
  extra_.Set(value, GetArenaForAllocation());
}
inline std::string* ReqStartCharge::_internal_mutable_extra() {
  
  return extra_.Mutable(GetArenaForAllocation());
}
inline std::string* ReqStartCharge::release_extra() {
  // @@protoc_insertion_point(field_release:ReqStartCharge.extra)
  return extra_.Release();
}
inline void ReqStartCharge::set_allocated_extra(std::string* extra) {
  if (extra != nullptr) {
    
  } else {
    
  }
  extra_.SetAllocated(extra, GetArenaForAllocation());
#ifdef PROTOBUF_FORCE_COPY_DEFAULT_STRING
  if (extra_.IsDefault()) {
    extra_.Set("", GetArenaForAllocation());
  }
#endif // PROTOBUF_FORCE_COPY_DEFAULT_STRING
  // @@protoc_insertion_point(field_set_allocated:ReqStartCharge.extra)
}

#ifdef __GNUC__
  #pragma GCC diagnostic pop
#endif  // __GNUC__
// -------------------------------------------------------------------

// -------------------------------------------------------------------

// -------------------------------------------------------------------

// -------------------------------------------------------------------


// @@protoc_insertion_point(namespace_scope)


// @@protoc_insertion_point(global_scope)

#include <google/protobuf/port_undef.inc>
#endif  // GOOGLE_PROTOBUF_INCLUDED_GOOGLE_PROTOBUF_INCLUDED_Charge_2eproto
