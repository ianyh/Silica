//
//  SIAccessibilityElement.m
//  Silica
//

#import "SIAccessibilityElement.h"
#import "SIApplication.h"

#define kAXEnhancedUserInterfaceKey CFSTR("AXEnhancedUserInterface")

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

    if (error != kAXErrorSuccess || !valueRef) return nil;
    if (CFGetTypeID(valueRef) != CFStringGetTypeID()) return nil;

    return CFBridgingRelease(valueRef);
}

- (NSNumber *)numberForKey:(CFStringRef)accessibilityValueKey {
    CFTypeRef valueRef;
    AXError error;

    error = AXUIElementCopyAttributeValue(self.axElementRef, accessibilityValueKey, &valueRef);

    if (error != kAXErrorSuccess || !valueRef) return nil;
    if (CFGetTypeID(valueRef) != CFNumberGetTypeID() && CFGetTypeID(valueRef) != CFBooleanGetTypeID()) return nil;
    
    return CFBridgingRelease(valueRef);
}

- (NSArray *)arrayForKey:(CFStringRef)accessibilityValueKey {
    CFArrayRef arrayRef;
    AXError error;

    error = AXUIElementCopyAttributeValues(self.axElementRef, accessibilityValueKey, 0, 100, &arrayRef);

    if (error != kAXErrorSuccess || !arrayRef) return nil;

    return CFBridgingRelease(arrayRef);
}

- (SIAccessibilityElement *)elementForKey:(CFStringRef)accessibilityValueKey {
    CFTypeRef valueRef;
    AXError error;

    error = AXUIElementCopyAttributeValue(self.axElementRef, accessibilityValueKey, &valueRef);

    if (error != kAXErrorSuccess || !valueRef) return nil;
    if (CFGetTypeID(valueRef) != AXUIElementGetTypeID()) return nil;

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
    if (error != kAXErrorSuccess || !sizeRef) return CGRectNull;
    
    CGPoint point;
    CGSize size;
    bool success;
    
    success = AXValueGetValue(pointRef, kAXValueCGPointType, &point);
    if (!success) return CGRectNull;
    
    success = AXValueGetValue(sizeRef, kAXValueCGSizeType, &size);
    if (!success) return CGRectNull;
    
    CGRect frame = { .origin.x = point.x, .origin.y = point.y, .size.width = size.width, .size.height = size.height };
    
    return frame;
}

- (void)setFrame:(CGRect)frame {
    CGSize threshold = { .width = 25, .height = 25 };
    [self setFrame:frame withThreshold:threshold];
}

- (void)setFrame:(CGRect)frame withThreshold:(CGSize)threshold {
    // We only want to set the size if the size has actually changed more than a given amount.
    CGRect currentFrame = self.frame;
    BOOL shouldSetSize = self.isResizable
        && (fabs(currentFrame.size.width - frame.size.width) >= threshold.width
        ||  fabs(currentFrame.size.height - frame.size.height) >= threshold.height);
    
    SIApplication *application = [self app];
    BOOL flag = [application numberForKey:kAXEnhancedUserInterfaceKey];
    if (flag) {
        [application setFlag:NO forKey:kAXEnhancedUserInterfaceKey];
    }

    // We set the size before and after setting the position because the
    // accessibility APIs are really finicky with setting size.
    // Note: this still occasionally silently fails to set the correct size.
    if (shouldSetSize) {
        self.size = frame.size;
    }

    if (!CGPointEqualToPoint(currentFrame.origin, frame.origin)) {
        self.position = frame.origin;
    }

    if (shouldSetSize) {
        self.size = frame.size;
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
            return;
        }
    }
}

- (void)setSize:(CGSize)size {
    AXValueRef sizeRef = AXValueCreate(kAXValueCGSizeType, &size);
    AXError error;
    
    if (!CGSizeEqualToSize(size, [self frame].size)) {
        error = AXUIElementSetAttributeValue(self.axElementRef, kAXSizeAttribute, sizeRef);
        if (error != kAXErrorSuccess) {
            return;
        }
    }
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
