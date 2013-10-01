//
//  SIWindow.h
//  Silica
//
//  Created by Steven Degutis on 2/28/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "SIAccessibilityElement.h"

@class SIApplication;

@interface SIWindow : SIAccessibilityElement

#pragma mark Window Accessors

+ (NSArray *)allWindows;
+ (NSArray *)visibleWindows;
+ (SIWindow *)focusedWindow;

- (NSArray *)otherWindowsOnSameScreen;
- (NSArray *)otherWindowsOnAllScreens;
- (NSArray *)windowsToWest;
- (NSArray *)windowsToEast;
- (NSArray *)windowsToNorth;
- (NSArray *)windowsToSouth;

#pragma mark Window Geometry

- (CGRect)frame;
- (CGPoint)topLeft;
- (CGSize)size;

- (void)setFrame:(CGRect)frame;
- (void)setTopLeft:(CGPoint)thePoint;
- (void)setSize:(CGSize)theSize;

#pragma mark Window Properties

- (NSString *)title;
- (BOOL)isWindowMinimized;
- (BOOL)isNormalWindow;

- (NSScreen *)screen;
- (SIApplication *)app;

#pragma mark Window Actions

- (void)maximize;
- (void)minimize;
- (void)unMinimize;

#pragma mark Window Focus

- (BOOL)focusWindow;

- (void)focusWindowLeft;
- (void)focusWindowRight;
- (void)focusWindowUp;
- (void)focusWindowDown;

@end
