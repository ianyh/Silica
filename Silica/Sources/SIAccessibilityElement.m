//
//  SIAccessibilityElement.m
//  Silica
//

#import <AppKit/AppKit.h>
#import "SIAccessibilityElement.h"
#import "SIApplication.h"

#define kAXEnhancedUserInterfaceKey CFSTR("AXEnhancedUserInterface")

static void setAXFrameAttribute(AXUIElementRef element, CFStringRef attribute, AXValueType type, const void *value) {
    AXValueRef valueRef = AXValueCreate(type, value);
    if (!valueRef) return;

    AXUIElementSetAttributeValue(element, attribute, valueRef);
    CFRelease(valueRef);
}

@interface SIAccessibilityElement ()
@property (nonatomic, assign) AXUIElementRef axElementRef;
@end

@implementation SIAccessibilityElement

#pragma mark Lifecycle

- (instancetype)init { return nil; }

- (instancetype)initWithAXElement:(AXUIElementRef)axElementRef {
    self = [super init];
    if (self) {
        self.axElementRef = CFRetain(axElementRef);
    }
    return self;
}

- (void)dealloc {
    CFRelease(_axElementRef);
}

#pragma mark NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ <Title: %@> <pid: %d>", super.description, [self stringForKey:kAXTitleAttribute], self.processIdentifier];
}

- (BOOL)isEqual:(id)object {
    if (!object)
        return NO;

    if (![object isKindOfClass:[self class]])
        return NO;

    SIAccessibilityElement *otherElement = object;
    if (CFEqual(self.axElementRef, otherElement.axElementRef))
        return YES;

    return NO;
}

- (NSUInteger)hash {
    return CFHash(self.axElementRef);
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithAXElement:self.axElementRef];
}

#pragma mark Public Accessors

- (BOOL)isResizable {
    Boolean sizeWriteable = false;
    AXError error = AXUIElementIsAttributeSettable(self.axElementRef, kAXSizeAttribute, &sizeWriteable);
    if (error != kAXErrorSuccess) return NO;
    
    return sizeWriteable;
}

- (BOOL)isMovable {
    Boolean positionWriteable = false;
    AXError error = AXUIElementIsAttributeSettable(self.axElementRef, kAXPositionAttribute, &positionWriteable);
    if (error != kAXErrorSuccess) return NO;
    
    return positionWriteable;
}

- (NSString *)stringForKey:(CFStringRef)accessibilityValueKey {
    CFTypeRef valueRef;
    AXError error;

    error = AXUIElementCopyAttributeValue(self.axElementRef, accessibilityValueKey, &valueRef);

    if (error != kAXErrorSuccess || !valueRef) {
        return nil;
    }
    
    if (CFGetTypeID(valueRef) != CFStringGetTypeID()) {
        CFRelease(valueRef);
        return nil;
    }

    return CFBridgingRelease(valueRef);
}

- (NSNumber *)numberForKey:(CFStringRef)accessibilityValueKey {
    CFTypeRef valueRef;
    AXError error;

    error = AXUIElementCopyAttributeValue(self.axElementRef, accessibilityValueKey, &valueRef);

    if (error != kAXErrorSuccess || !valueRef) {
        return nil;
    }

    if (CFGetTypeID(valueRef) != CFNumberGetTypeID() && CFGetTypeID(valueRef) != CFBooleanGetTypeID()) {
        CFRelease(valueRef);
        return nil;
    }
    
    return CFBridgingRelease(valueRef);
}

- (NSArray *)arrayForKey:(CFStringRef)accessibilityValueKey {
    CFArrayRef arrayRef;
    AXError error;

    error = AXUIElementCopyAttributeValues(self.axElementRef, accessibilityValueKey, 0, 100, &arrayRef);

    if (error != kAXErrorSuccess || !arrayRef) {
        return nil;
    }

    return CFBridgingRelease(arrayRef);
}

- (SIAccessibilityElement *)elementForKey:(CFStringRef)accessibilityValueKey {
    CFTypeRef valueRef;
    AXError error;

    error = AXUIElementCopyAttributeValue(self.axElementRef, accessibilityValueKey, &valueRef);

    if (error != kAXErrorSuccess || !valueRef) {
        return nil;
    }
    
    if (CFGetTypeID(valueRef) != AXUIElementGetTypeID()) {
        CFRelease(valueRef);
        return nil;
    }

    SIAccessibilityElement *element = [[SIAccessibilityElement alloc] initWithAXElement:(AXUIElementRef)valueRef];

    CFRelease(valueRef);

    return element;
}

- (CGRect)frame {
    CFTypeRef pointRef;
    CFTypeRef sizeRef;
    AXError error;
    
    error = AXUIElementCopyAttributeValue(self.axElementRef, kAXPositionAttribute, &pointRef);
    if (error != kAXErrorSuccess || !pointRef) return CGRectNull;
    
    error = AXUIElementCopyAttributeValue(self.axElementRef, kAXSizeAttribute, &sizeRef);
    if (error != kAXErrorSuccess || !sizeRef) {
        CFRelease(pointRef);
        return CGRectNull;
    }
    
    CGPoint point;
    CGSize size;
    bool success;
    
    success = AXValueGetValue(pointRef, kAXValueCGPointType, &point);
    if (!success) {
        CFRelease(pointRef);
        CFRelease(sizeRef);
        return CGRectNull;
    }
    
    success = AXValueGetValue(sizeRef, kAXValueCGSizeType, &size);
    if (!success) {
        CFRelease(pointRef);
        CFRelease(sizeRef);
        return CGRectNull;
    }
    
    CGRect frame = { .origin.x = point.x, .origin.y = point.y, .size.width = size.width, .size.height = size.height };
    CFRelease(pointRef);
    CFRelease(sizeRef);
    return frame;
}

- (void)setFrame:(CGRect)frame {
    CGSize threshold = { .width = 25, .height = 25 };
    [self setFrame:frame withThreshold:threshold];
}

- (void)setFrame:(CGRect)frame withThreshold:(CGSize)threshold {
    CGRect currentFrame = self.frame;
    BOOL frameUnavailable = CGRectIsNull(currentFrame);

    // Resize only when a dimension reaches its threshold.
    BOOL sizeDiffers = fabs(currentFrame.size.width - frame.size.width) >= threshold.width
        || fabs(currentFrame.size.height - frame.size.height) >= threshold.height;
    BOOL shouldSetSize = sizeDiffers && self.isResizable;
    BOOL shouldSetPosition = !CGPointEqualToPoint(currentFrame.origin, frame.origin);
    if (!frameUnavailable && !shouldSetSize && !shouldSetPosition) return;

    SIApplication *application = [self app];
    BOOL flag = [[application numberForKey:kAXEnhancedUserInterfaceKey] boolValue];
    if (flag) {
        [application setFlag:NO forKey:kAXEnhancedUserInterfaceKey];
    }

    // Apps can clamp size at the old position. Retry after moving if needed.
    // The app can still reject the requested size without reporting an error.
    if (frameUnavailable) {
        // Keep the public setters' frame checks when the initial read fails.
        if (shouldSetSize) self.size = frame.size;
        if (shouldSetPosition) self.position = frame.origin;
        if (shouldSetSize) self.size = frame.size;
    } else {
        if (shouldSetSize) {
            setAXFrameAttribute(self.axElementRef, kAXSizeAttribute, kAXValueCGSizeType, &frame.size);
        }
        if (shouldSetPosition) {
            setAXFrameAttribute(self.axElementRef, kAXPositionAttribute, kAXValueCGPointType, &frame.origin);
        }
        if (shouldSetSize) {
            CFTypeRef sizeRef = NULL;
            AXError error = AXUIElementCopyAttributeValue(self.axElementRef, kAXSizeAttribute, &sizeRef);
            if (sizeRef) {
                CGSize size;
                if (error == kAXErrorSuccess && CFGetTypeID(sizeRef) == AXValueGetTypeID()
                    && AXValueGetValue(sizeRef, kAXValueCGSizeType, &size)
                    && !CGSizeEqualToSize(size, frame.size)) {
                    setAXFrameAttribute(self.axElementRef, kAXSizeAttribute, kAXValueCGSizeType, &frame.size);
                }
                CFRelease(sizeRef);
            }
        }
    }
    
    if (flag) {
        [application setFlag:flag forKey:kAXEnhancedUserInterfaceKey];
    }
}

- (void)setPosition:(CGPoint)position {
    AXValueRef positionRef = AXValueCreate(kAXValueCGPointType, &position);
    AXError error;
    
    if (!CGPointEqualToPoint(position, [self frame].origin)) {
        error = AXUIElementSetAttributeValue(self.axElementRef, kAXPositionAttribute, positionRef);
        if (error != kAXErrorSuccess) {
            CFRelease(positionRef);
            return;
        }
    }
    
    CFRelease(positionRef);
}

- (void)setSize:(CGSize)size {
    AXValueRef sizeRef = AXValueCreate(kAXValueCGSizeType, &size);
    AXError error;
    
    if (!CGSizeEqualToSize(size, [self frame].size)) {
        error = AXUIElementSetAttributeValue(self.axElementRef, kAXSizeAttribute, sizeRef);
        if (error != kAXErrorSuccess) {
            CFRelease(sizeRef);
            return;
        }
    }
    
    CFRelease(sizeRef);
}

- (BOOL)setFlag:(BOOL)flag forKey:(CFStringRef)accessibilityValueKey {
    AXError error;
    
    error = AXUIElementSetAttributeValue(self.axElementRef, accessibilityValueKey, flag ? kCFBooleanTrue : kCFBooleanFalse);
    
    return error != kAXErrorSuccess;
}

- (pid_t)processIdentifier {
    pid_t processIdentifier;
    AXError error;
    
    error = AXUIElementGetPid(self.axElementRef, &processIdentifier);
    
    if (error != kAXErrorSuccess) return -1;
    
    return processIdentifier;
}

- (SIApplication *)app {
    NSRunningApplication *runningApplication = [NSRunningApplication runningApplicationWithProcessIdentifier:self.processIdentifier];
    if (!runningApplication) {
        return nil;
    }
    return [SIApplication applicationWithRunningApplication:runningApplication];
}

@end
