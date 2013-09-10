//
//  SDObserver.h
//  Zephyros
//
//  Created by Steven Degutis on 8/30/13.
//  Copyright (c) 2013 Giant Robot Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDObserver : NSObject

+ (SDObserver*) observe:(CFStringRef)event on:(AXUIElementRef)thing callback:(void(^)(AXUIElementRef element))callback;

@end
