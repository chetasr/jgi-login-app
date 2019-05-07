#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "UnityAdsFlutterPlugin.h"

FOUNDATION_EXPORT double unity_ads_flutterVersionNumber;
FOUNDATION_EXPORT const unsigned char unity_ads_flutterVersionString[];

