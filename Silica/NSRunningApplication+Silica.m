//
//  NSRunningApplication+Manageable.m
//  Silica
//
//  Created by Ian Ynda-Hummel on 5/24/13.
//  Copyright (c) 2013 Ian Ynda-Hummel. All rights reserved.
//

#import "NSRunningApplication+Silica.h"

@implementation NSRunningApplication (Silica)

- (BOOL)isAgent {
    NSURL *bundleInfoPath = [[self.bundleURL URLByAppendingPathComponent:@"Contents"] URLByAppendingPathComponent:@"Info.plist"];
    NSDictionary *applicationBundleInfoDictionary = [NSDictionary dictionaryWithContentsOfURL:bundleInfoPath];
    return [applicationBundleInfoDictionary[@"LSUIElement"] boolValue];
}

@end
