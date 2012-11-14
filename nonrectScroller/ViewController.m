//
//  ViewController.m
//  ;
//
//  Created by Rob Mayoff on 11/13/12.
//  Copyright (c) 2012 Rob Mayoff. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>

static const CGSize kPageSize = { 200, 300 };
typedef struct {
    int x;
    int y;
} MapPosition;

@interface ViewController () <UIScrollViewDelegate>

@end

@implementation ViewController {
    NSArray *map_;
    MapPosition mapPosition_;
    UIScrollView *scrollView_;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self initMap];
    }
    return self;
}

- (void)initMap {
    NSNull *null = [NSNull null];
    map_ = @[
    @[ @"1", null, @"2"],
    @[ @"3", @"4", @"5" ],
    @[ null, @"6", @"7" ],
    @[ null, null, @"8" ],
    ];
    mapPosition_ = (MapPosition){ 0, 0 };
}

- (void)loadView {
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [map_[0] count] * kPageSize.width, map_.count * kPageSize.height)];
    contentView.backgroundColor = [UIColor colorWithHue:0.1 saturation:0.1 brightness:0.9 alpha:1];
    [self addPageViewsToContentView:contentView];

    scrollView_ = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kPageSize.width, kPageSize.height)];
    scrollView_.delegate= self;
    scrollView_.bounces = NO;
    scrollView_.contentSize = contentView.frame.size;
    [scrollView_ addSubview:contentView];
    scrollView_.contentOffset = [self contentOffsetForCurrentMapPosition];
    scrollView_.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin
                                    | UIViewAutoresizingFlexibleRightMargin
                                    | UIViewAutoresizingFlexibleTopMargin
                                    | UIViewAutoresizingFlexibleBottomMargin);

    UIView *myView = [[UIView alloc] initWithFrame:scrollView_.frame];
    [myView addSubview:scrollView_];
    myView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.view = myView;
}

- (CGPoint)contentOffsetForCurrentMapPosition {
    return [self contentOffsetForMapPosition:mapPosition_];
}

- (CGPoint)contentOffsetForMapPosition:(MapPosition)position {
    return CGPointMake(position.x * kPageSize.width, position.y * kPageSize.height);
}

- (void)addPageViewsToContentView:(UIView *)contentView {
    for (int y = 0, yMax = map_.count; y < yMax; ++y) {
        NSArray *mapRow = map_[y];
        for (int x = 0, xMax = mapRow.count; x < xMax; ++x) {
            id page = mapRow[x];
            if (![page isKindOfClass:[NSNull class]]) {
                [self addPageViewForPage:page x:x y:y toContentView:contentView];
            }
        }
    }
}

- (void)addPageViewForPage:(NSString *)page x:(int)x y:(int)y toContentView:(UIView *)contentView {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(CGRectMake(x * kPageSize.width, y * kPageSize.height, kPageSize.width, kPageSize.height), 10, 10)];
    label.text = page;
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.shadowOffset = CGSizeMake(0, 2);
    label.layer.shadowRadius = 2;
    label.layer.shadowOpacity = 0.3;
    label.layer.shadowPath = [UIBezierPath bezierPathWithRect:label.bounds].CGPath;
    label.clipsToBounds = NO;
    [contentView addSubview:label];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint contentOffset = scrollView_.contentOffset;
    CGPoint constrainedContentOffset = [self contentOffsetByConstrainingMovementToOneDimension:contentOffset];
    constrainedContentOffset = [self contentOffsetByConstrainingToAccessiblePoint:constrainedContentOffset];
    if (!CGPointEqualToPoint(contentOffset, constrainedContentOffset)) {
        scrollView_.contentOffset = constrainedContentOffset;
    }
    mapPosition_ = [self mapPositionForContentOffset:constrainedContentOffset];
}

- (MapPosition)mapPositionForContentOffset:(CGPoint)contentOffset {
    return (MapPosition){ roundf(contentOffset.x / kPageSize.width),
        roundf(contentOffset.y / kPageSize.height) };
}

- (CGPoint)contentOffsetByConstrainingMovementToOneDimension:(CGPoint)contentOffset {
    CGPoint baseContentOffset = [self contentOffsetForCurrentMapPosition];
    CGFloat dx = contentOffset.x - baseContentOffset.x;
    CGFloat dy = contentOffset.y - baseContentOffset.y;
    if (fabsf(dx) < fabsf(dy)) {
        contentOffset.x = baseContentOffset.x;
    } else {
        contentOffset.y = baseContentOffset.y;
    }
    return contentOffset;
}

- (CGPoint)contentOffsetByConstrainingToAccessiblePoint:(CGPoint)contentOffset {
    return [self isAccessiblePoint:contentOffset] ? contentOffset : [self contentOffsetForCurrentMapPosition];
}

- (BOOL)isAccessiblePoint:(CGPoint)point {
    CGFloat x = point.x / kPageSize.width;
    CGFloat y = point.y / kPageSize.height;
    return [self isAccessibleMapPosition:(MapPosition){ floorf(x), floorf(y) }]
        && [self isAccessibleMapPosition:(MapPosition){ ceilf(x), ceilf(y) }];
}

- (BOOL)isAccessibleMapPosition:(MapPosition)p {
    if (p.y < 0 || p.y >= map_.count)
        return NO;
    NSArray *mapRow = map_[p.y];
    if (p.x < 0 || p.x >= mapRow.count)
        return NO;
    return ![mapRow[p.x] isKindOfClass:[NSNull class]];
}

static int sign(CGFloat value) {
    return value > 0 ? 1 : -1;
}

static int directionForVelocity(CGFloat velocity) {
    static const CGFloat kVelocityThreshold = 0.1;
    return fabsf(velocity) < kVelocityThreshold ? 0 : sign(velocity);
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (fabsf(velocity.x) > fabsf(velocity.y)) {
        *targetContentOffset = [self contentOffsetForPageInHorizontalDirection:directionForVelocity(velocity.x)];
    } else {
        *targetContentOffset = [self contentOffsetForPageInVerticalDirection:directionForVelocity(velocity.y)];
    }
}

- (CGPoint)contentOffsetForPageInHorizontalDirection:(int)direction {
    MapPosition newPosition = (MapPosition){ mapPosition_.x + direction, mapPosition_.y };
    return [self isAccessibleMapPosition:newPosition] ? [self contentOffsetForMapPosition:newPosition] : [self contentOffsetForCurrentMapPosition];
}

- (CGPoint)contentOffsetForPageInVerticalDirection:(int)direction {
    MapPosition newPosition = (MapPosition){ mapPosition_.x, mapPosition_.y + direction };
    return [self isAccessibleMapPosition:newPosition] ? [self contentOffsetForMapPosition:newPosition] : [self contentOffsetForCurrentMapPosition];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [scrollView_ setContentOffset:[self contentOffsetForCurrentMapPosition] animated:YES];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint goodContentOffset = [self contentOffsetForCurrentMapPosition];
    if (!CGPointEqualToPoint(scrollView_.contentOffset, goodContentOffset)) {
        [scrollView_ setContentOffset:goodContentOffset animated:YES];
    }
}

@end
