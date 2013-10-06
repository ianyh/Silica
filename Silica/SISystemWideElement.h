//
//  SISystemWideElement.h
//  Silica
//
//  Created by Ian on 5/19/13.
//  Copyright (c) 2013 Ian Ynda-Hummel. All rights reserved.
//

#import "SIAccessibilityElement.h"

/**
 *  Wrapper around the system-wide element.
 */
@interface SISystemWideElement : SIAccessibilityElement

/**
 *  Returns a globally shared reference to the system-wide accessibility element.
 *
 *  @return A globally shared reference to the system-wide accessibility element.
 */
+ (SISystemWideElement *)systemWideElement;

@end
