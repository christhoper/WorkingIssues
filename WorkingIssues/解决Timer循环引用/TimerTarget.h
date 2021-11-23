//
//  TimerTarget.h
//  WorkingIssues
//
//  Created by bailun on 2021/9/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TimerTarget : NSProxy

@property (nonatomic, weak) id target;

@end

NS_ASSUME_NONNULL_END
