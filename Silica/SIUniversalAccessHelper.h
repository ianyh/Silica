//
//  SIUniversalAccessHelper.h
//  Silica
//
//  Created by Steven Degutis on 3/1/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
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
