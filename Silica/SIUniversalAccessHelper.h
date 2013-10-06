//
//  SIUniversalAccessHelper.h
//  Silica
//

#import <Foundation/Foundation.h>

@interface SIUniversalAccessHelper : NSObject

/**
 *  @return YES if accessibility is enabled and NO otherwise.
 */
+ (BOOL)accessibilityEnabled;

/**
 *  If accessibility is not enabled presents an alert requesting that the user enable accessibility.
 */
+ (void)complainIfNeeded;

@end
