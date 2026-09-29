//
//  SIApplication.m
//  Silica
//

#import "SIApplication.h"

#import <AppKit/AppKit.h>
#import "SIWindow.h"
#import "SIUniversalAccessHelper.h"

@interface SIApplicationObservation : NSObject
@property (nonatomic, strong) NSString *notification;
@property (nonatomic, copy) SIAXNotificationHandler handler;
@end

@implementation SIApplicationObservation
@end

@interface SIApplication ()
@property (nonatomic, assign) AXObserverRef observerRef;
/// Whether the current observer was created with the application as its context; fixed for the observer's lifetime.
@property (nonatomic, assign) BOOL observerUsesApplicationCallback;
@property (nonatomic, strong) NSMutableDictionary *elementToObservations;

@property (nonatomic, strong) NSMutableArray *cachedWindows;
@end

@implementation SIApplication

#pragma mark Lifecycle

+ (instancetype)applicationWithRunningApplication:(NSRunningApplication *)runningApplication {
    AXUIElementRef axElementRef = AXUIElementCreateApplication(runningApplication.processIdentifier);
    SIApplication *application = [[SIApplication alloc] initWithAXElement:axElementRef];
    CFRelease(axElementRef);
    return application;
}

+ (NSArray *)runningApplications {
    if (![SIUniversalAccessHelper isAccessibilityTrusted])
        return nil;

    NSMutableArray *apps = [NSMutableArray array];

    for (NSRunningApplication *runningApp in [[NSWorkspace sharedWorkspace] runningApplications]) {
        SIApplication *app = [SIApplication applicationWithRunningApplication:runningApp];
        [apps addObject:app];
    }

    return apps;
}

- (void)dealloc {
    if (_observerRef) {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(_observerRef), kCFRunLoopDefaultMode);
        for (SIAccessibilityElement *element in self.elementToObservations.allKeys) {
            for (SIApplicationObservation *observation in self.elementToObservations[element]) {
                AXObserverRemoveNotification(_observerRef, element.axElementRef, (__bridge CFStringRef)observation.notification);
            }
        }
        CFRunLoopSourceInvalidate(AXObserverGetRunLoopSource(_observerRef));
        CFRelease(_observerRef);
    }
}

#pragma mark AXObserver

void observerCallback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon) {
    SIAXNotificationHandler callback = (__bridge SIAXNotificationHandler)refcon;
    SIWindow *window = [[SIWindow alloc] initWithAXElement:element];
    callback(window);
}

void applicationObserverCallback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon) {
    SIApplication *application = (__bridge SIApplication *)refcon;
    [application deliverNotification:notification forElement:element];
}

- (void)setUsesApplicationCallback:(BOOL)usesApplicationCallback {
    if (usesApplicationCallback == _usesApplicationCallback) return;
    NSAssert(!self.observerRef, @"usesApplicationCallback cannot change while notifications are observed");
    _usesApplicationCallback = usesApplicationCallback;
}

/// The handler registered for `notification` on `element`, or failing that on the application; nil once the registration is gone.
- (SIAXNotificationHandler)handlerForNotification:(CFStringRef)notification element:(AXUIElementRef)element {
    SIAXNotificationHandler applicationHandler = nil;
    for (SIAccessibilityElement *registered in self.elementToObservations) {
        BOOL matchesElement = CFEqual(registered.axElementRef, element);
        BOOL matchesApplication = CFEqual(registered.axElementRef, self.axElementRef);
        if (!matchesElement && !matchesApplication) continue;
        for (SIApplicationObservation *observation in self.elementToObservations[registered]) {
            if (!CFEqual((__bridge CFStringRef)observation.notification, notification)) continue;
            if (matchesElement) return observation.handler;
            applicationHandler = observation.handler;
        }
    }
    return applicationHandler;
}

- (void)deliverNotification:(CFStringRef)notification forElement:(AXUIElementRef)element {
    SIAXNotificationHandler handler = [self handlerForNotification:notification element:element];
    if (!handler) return;
    SIWindow *window = [[SIWindow alloc] initWithAXElement:element];
    handler(window);
}

- (AXError)observeNotification:(CFStringRef)notification withElement:(SIAccessibilityElement *)accessibilityElement handler:(SIAXNotificationHandler)handler {
    if (!self.observerRef) {
        AXObserverRef observerRef;
        AXObserverCallback callback = self.usesApplicationCallback ? &applicationObserverCallback : &observerCallback;
        AXError error = AXObserverCreate(self.processIdentifier, callback, &observerRef);

        if (error != kAXErrorSuccess) return error;

        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observerRef), kCFRunLoopDefaultMode);

        self.observerRef = observerRef;
        self.observerUsesApplicationCallback = self.usesApplicationCallback;
        self.elementToObservations = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    
    void *refcon = self.observerUsesApplicationCallback ? (__bridge void *)self : (__bridge void *)handler;
    AXError error = AXObserverAddNotification(self.observerRef, accessibilityElement.axElementRef, notification, refcon);
    
    if (error != kAXErrorSuccess && error != kAXErrorNotificationAlreadyRegistered) {
        return error;
    }
    
    if (error == kAXErrorNotificationAlreadyRegistered) {
        return error;
    }
    
    SIApplicationObservation *observation = [[SIApplicationObservation alloc] init];
    observation.notification = (__bridge NSString *)notification;
    observation.handler = handler;

    if (!self.elementToObservations[accessibilityElement]) {
        self.elementToObservations[accessibilityElement] = [NSMutableArray array];
    }
    [self.elementToObservations[accessibilityElement] addObject:observation];
    
    return error;
}

- (void)unobserveNotification:(CFStringRef)notification withElement:(SIAccessibilityElement *)accessibilityElement {
    NSMutableArray<SIApplicationObservation *> *observations = self.elementToObservations[accessibilityElement];
    NSMutableArray<SIApplicationObservation *> *removed = [NSMutableArray array];
    for (SIApplicationObservation *observation in observations) {
        if (!CFEqual((__bridge CFStringRef)observation.notification, notification)) continue;
        AXObserverRemoveNotification(self.observerRef, accessibilityElement.axElementRef, notification);
        [removed addObject:observation];
    }
    [observations removeObjectsInArray:removed];
    if (observations.count == 0) {
        [self.elementToObservations removeObjectForKey:accessibilityElement];
    }
    
    if (self.elementToObservations.count == 0 && self.observerRef) {
        CFRunLoopSourceInvalidate(AXObserverGetRunLoopSource(self.observerRef));
        CFRelease(self.observerRef);
        self.observerRef = nil;
    }
}

#pragma mark Public Accessors

- (NSArray *)windows {
    if (!self.cachedWindows) {
        self.cachedWindows = [NSMutableArray array];
        NSArray *windowRefs = [self arrayForKey:kAXWindowsAttribute];
        for (NSUInteger index = 0; index < windowRefs.count; ++index) {
            AXUIElementRef windowRef = (__bridge AXUIElementRef)windowRefs[index];
            SIWindow *window = [[SIWindow alloc] initWithAXElement:windowRef];

            [self.cachedWindows addObject:window];
        }
    }
    return self.cachedWindows;
}

- (NSArray *)visibleWindows {
    return [self.windows filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SIWindow *window, NSDictionary *bindings) {
        return ![[window app] isHidden] && ![window isWindowMinimized] && [window isNormalWindow];
    }]];
}

- (NSString *)title {
    return [self stringForKey:kAXTitleAttribute];
}

- (BOOL)isHidden {
    return [[self numberForKey:kAXHiddenAttribute] boolValue];
}

- (void)hide {
    [[NSRunningApplication runningApplicationWithProcessIdentifier:self.processIdentifier] hide];
}

- (void)unhide {
    [[NSRunningApplication runningApplicationWithProcessIdentifier:self.processIdentifier] unhide];
}

- (void)kill {
    [[NSRunningApplication runningApplicationWithProcessIdentifier:self.processIdentifier] terminate];
}

- (void)kill9 {
    [[NSRunningApplication runningApplicationWithProcessIdentifier:self.processIdentifier] forceTerminate];
}

- (void)dropWindowsCache {
    self.cachedWindows = nil;
}

@end
