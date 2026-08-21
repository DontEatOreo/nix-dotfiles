#include "PrivateIOKit.h"

typedef CFTypeRef IOAVServiceRef;

static_assert(sizeof(io_service_t) == sizeof(uint32_t),
              "the private IOAV ABI requires a 32-bit service port");
static_assert(sizeof(IOReturn) == sizeof(int32_t),
              "the private IOAV ABI requires a 32-bit I/O result");

extern IOAVServiceRef _Nullable IOAVServiceCreateWithService(
    CFAllocatorRef _Nullable allocator, io_service_t service);
extern IOReturn IOAVServiceCopyEDID(IOAVServiceRef service,
                                    CFDataRef _Nullable *_Nonnull edid);
extern IOReturn IOAVServiceSetVirtualEDIDMode(IOAVServiceRef service, uint32_t mode,
                                              CFDataRef _Nullable edid);

HDAAVServiceRef HDAAVServiceCreate(io_service_t service) {
  return (HDAAVServiceRef)IOAVServiceCreateWithService(kCFAllocatorDefault, service);
}

void HDAAVServiceRelease(HDAAVServiceRef service) {
  if (service != nullptr) {
    CFRelease((CFTypeRef)service);
  }
}

CFDataRef HDAAVServiceCopyEDID(HDAAVServiceRef service, IOReturn *status) {
  CFDataRef edid = nullptr;
  *status = IOAVServiceCopyEDID((IOAVServiceRef)service, &edid);
  return edid;
}

IOReturn HDAAVServiceSetVirtualEDID(HDAAVServiceRef service, CFDataRef edid) {
  return IOAVServiceSetVirtualEDIDMode((IOAVServiceRef)service, edid == nullptr ? 0 : 1,
                                       edid);
}
