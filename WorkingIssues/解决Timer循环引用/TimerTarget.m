//
//  TimerTarget.m
//  WorkingIssues
//
//  Created by bailun on 2021/9/13.
//

#import "TimerTarget.h"

@implementation TimerTarget


- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}


@end
