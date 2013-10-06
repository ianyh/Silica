//
//  NSRunningApplication+Manageable.h
//  Silica
//
//  Created by Ian Ynda-Hummel on 5/24/13.
//  Copyright (c) 2013 Ian Ynda-Hummel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  A category defining helper methods on NSRunningApplication that are generally useful for window management.
 */
@interface NSRunningApplication (Silica)

/**
 *  Returns a BOOL indicating whether or not the application is an agent.
 *
 *  @return YES if the application is an agent and NO otherwise.
 */
- (BOOL)isAgent;

@end
