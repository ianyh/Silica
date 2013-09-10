//
//  SDObserver.m
//  Zephyros
//
//  Created by Steven Degutis on 8/30/13.
//  Copyright (c) 2013 Giant Robot Software. All rights reserved.
//

#import "SDObserver.h"



@interface SDObserver ()

@property AXObserverRef observer;

@property AXUIElementRef thing;
@property CFStringRef event;
@property (copy) void(^callback)(AXUIElementRef element);

@end


static void observer_callback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *_self) {
    SDObserver* self = (__bridge SDObserver*)_self;
    self.callback(element);
}


@implementation SDObserver

+ (SDObserver*) observe:(CFStringRef)event on:(AXUIElementRef)thing callback:(void(^)(AXUIElementRef element))callback {
    SDObserver* o = [[SDObserver alloc] init];
    o.thing = thing;
    o.event = CFRetain(event);
    o.callback = callback;
    [o startObserving];
    return o;
}

- (void) dealloc {
    [self stopObserving];
    CFRelease(self.event);
}

- (void) stopObserving {
    if (!self.observer)
        return;
    
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(self.observer), kCFRunLoopDefaultMode);
    AXObserverRemoveNotification(self.observer, self.thing, self.event);
    
    CFRelease(self.observer);
    self.observer = nil;
}

- (void) startObserving {
    pid_t pid;
    AXUIElementGetPid(self.thing, &pid);
    
    AXObserverRef observer;
    AXError err = AXObserverCreate(pid, observer_callback, &observer);
    if (err != kAXErrorSuccess) {
//        NSLog(@"start observing stuff failed at point #1 with: %d", err);
        return;
    }
    
    self.observer = observer;
    
    AXObserverAddNotification(self.observer, self.thing, self.event, (__bridge void*)self);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(self.observer), kCFRunLoopDefaultMode);
}

@end
