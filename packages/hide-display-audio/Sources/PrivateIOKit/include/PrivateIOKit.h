#ifndef HIDE_DISPLAY_AUDIO_PRIVATE_IOKIT_H
#define HIDE_DISPLAY_AUDIO_PRIVATE_IOKIT_H

// Swift imports Clang modules in Objective-C mode, which has no
// __STDC_VERSION__. Every C translation unit must use ISO C23 or newer.
#if !defined(__OBJC__) && (!defined(__STDC_VERSION__) || __STDC_VERSION__ < 202311L)
#error "PrivateIOKit requires ISO C23 or newer"
#endif

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <stdint.h>

// Clang nullability and CoreFoundation ownership annotations preserve the
// optionality and lifetime contract when this C API is imported into Swift.
CF_ASSUME_NONNULL_BEGIN

typedef struct HDAAVService *HDAAVServiceRef;

[[nodiscard("the returned service must be released")]]
HDAAVServiceRef _Nullable HDAAVServiceCreate(io_service_t service);
void HDAAVServiceRelease(HDAAVServiceRef _Nullable service);

[[nodiscard("the returned EDID and I/O status must be checked")]]
CFDataRef _Nullable HDAAVServiceCopyEDID(HDAAVServiceRef service,
                                         IOReturn *_Nonnull status) CF_RETURNS_RETAINED;

[[nodiscard("the I/O status must be checked")]]
IOReturn HDAAVServiceSetVirtualEDID(HDAAVServiceRef service, CFDataRef _Nullable edid);

CF_ASSUME_NONNULL_END

#endif
