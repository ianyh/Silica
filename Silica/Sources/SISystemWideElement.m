//
//  SISystemWideElement.m
//  Silica
//

#import "SISystemWideElement.h"

#import <AppKit/AppKit.h>
#import "CGSInternal/CGSHotKeys.h"

@implementation SISystemWideElement

+ (SISystemWideElement *)systemWideElement {
    static SISystemWideElement *sharedElement = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AXUIElementRef elementRef = AXUIElementCreateSystemWide();
        sharedElement = [[SISystemWideElement alloc] initWithAXElement:elementRef];
        CFRelease(elementRef);
    });
    return sharedElement;
}

+ (void)switchToSpace:(NSUInteger)space {
    NSEvent *event = [self eventForSwitchingToSpace:space];
    [self switchToSpaceWithEvent:event];
}

+ (NSEvent *)eventForSwitchingToSpace:(NSUInteger)space {
    if (space < 1 || space > 16) return nil;

    CGSSymbolicHotKey hotKey = (unsigned short)(118 + space - 1);
    CGSModifierFlags flags;
    CGKeyCode keyCode = 0;
    CGError error = CGSGetSymbolicHotKeyValue(hotKey, nil, &keyCode, &flags);
    
    if (error != kCGErrorSuccess) return nil;
    
    if (!CGSIsSymbolicHotKeyEnabled(hotKey)) {
        error = CGSSetSymbolicHotKeyEnabled(hotKey, true);
    }
    
    CGEventRef keyboardEvent = CGEventCreateKeyboardEvent(NULL, keyCode, true);
    CGEventSetFlags(keyboardEvent, (CGEventFlags)flags);

    NSEvent *event = [NSEvent eventWithCGEvent:keyboardEvent];

    CFRelease(keyboardEvent);
    
    return event;
}

+ (void)switchToSpaceWithEvent:(NSEvent *)event {
    if (event == nil) return;

    CGEventRef keyboardEventUp = CGEventCreateKeyboardEvent(NULL, event.keyCode, false);

    CGEventSetFlags(keyboardEventUp, 0);

    // Send the shortcut command to get Mission Control to switch spaces from under the window.
    CGEventPost(kCGHIDEventTap, event.CGEvent);
    CGEventPost(kCGHIDEventTap, keyboardEventUp);

    CFRelease(keyboardEventUp);
}

@end
