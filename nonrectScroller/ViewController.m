//
//  ViewController.m
//  ;
//
//  Created by Rob Mayoff on 11/13/12.
//  Copyright (c) 2012 Rob Mayoff. All rights reserved.
//

#import "ViewController.h"

static const CGSize kPageSize = { 100, 100 };
typedef struct {
    int x;
    int y;
} MapPosition;

@interface ViewController () <UIScrollViewDelegate>

@end

@implementation ViewController {
    NSArray *map_;
    MapPosition mapPosition_;
    UIScrollView *verticalScroller_;
    UIScrollView *horizontalScroller_;
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
    contentView.backgroundColor = [UIColor redColor];
    [self addPageViewsToContentView:contentView];

    verticalScroller_ = [self newScrollView];
    verticalScroller_.frame = CGRectMake(0, 0, contentView.frame.size.width, kPageSize.height);
    verticalScroller_.contentSize = contentView.frame.size;
    [verticalScroller_ addSubview:contentView];
    verticalScroller_.contentOffset = [self verticalContentOffsetForCurrentMapPosition];

    horizontalScroller_ = [self newScrollView];
    horizontalScroller_.frame = CGRectMake(0, 0, kPageSize.width, kPageSize.height);
    horizontalScroller_.contentSize = verticalScroller_.frame.size;
    [horizontalScroller_ addSubview:verticalScroller_];
    horizontalScroller_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin
        | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    horizontalScroller_.contentOffset = [self horizontalContentOffsetForCurrentMapPosition];

    UIView *myView = [[UIView alloc] initWithFrame:horizontalScroller_.frame];
    [myView addSubview:horizontalScroller_];
    myView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.view = myView;
}

- (CGPoint)horizontalContentOffsetForCurrentMapPosition {
    return CGPointMake(mapPosition_.x * kPageSize.width, 0);
}

- (CGPoint)verticalContentOffsetForCurrentMapPosition {
    return CGPointMake(0, mapPosition_.y * kPageSize.height);
}

- (UIScrollView *)newScrollView {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.bounces = NO;
    scrollView.delegate = self;
    return scrollView;
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
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x * kPageSize.width, y * kPageSize.height, kPageSize.width, kPageSize.height)];
    label.text = page;
    label.textAlignment = NSTextAlignmentCenter;
    [contentView addSubview:label];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self constrainHorizontalScroller];
    [self constrainVerticalScroller];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self updateMapPositionFromScrollViewContentOffsets];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateMapPositionFromScrollViewContentOffsets];
}

- (void)updateMapPositionFromScrollViewContentOffsets {
    mapPosition_ = (MapPosition){ roundf(horizontalScroller_.contentOffset.x / kPageSize.width),
        roundf(verticalScroller_.contentOffset.y / kPageSize.height) };
    NSLog(@"mapPosition updated to %d,%d", mapPosition_.x, mapPosition_.y);
}

static CGFloat clampMagnitude(CGFloat value, CGFloat maxMagnitude) {
    return (value < -maxMagnitude ? -maxMagnitude
            : value > maxMagnitude ? maxMagnitude
            : value);
}

static int sign(CGFloat value) {
    return value < 0 ? -1 : 1;
}

- (void)constrainHorizontalScroller {
    CGPoint baseContentOffset = [self horizontalContentOffsetForCurrentMapPosition];
    CGFloat xDeltaUnclamped = horizontalScroller_.contentOffset.x - baseContentOffset.x;
    if (xDeltaUnclamped == 0)
        return;
    
    BOOL shouldSetContentOffset = NO;

    CGFloat xDelta = clampMagnitude(xDeltaUnclamped, kPageSize.width);
    if (xDelta != xDeltaUnclamped) {
        shouldSetContentOffset = YES;
    }

    if (![self allowGoingToMapX:mapPosition_.x + sign(xDelta) y:mapPosition_.y]) {
        xDelta = 0;
        shouldSetContentOffset = YES;
    }

    if (shouldSetContentOffset) {
        baseContentOffset.x += xDelta;
        horizontalScroller_.contentOffset = baseContentOffset;
    }
}

- (void)constrainVerticalScroller {
    CGPoint baseContentOffset = [self verticalContentOffsetForCurrentMapPosition];
    CGFloat yDeltaUnclamped = verticalScroller_.contentOffset.y - baseContentOffset.y;
    if (yDeltaUnclamped == 0)
        return;

    BOOL shouldSetContentOffset = NO;

    CGFloat yDelta = clampMagnitude(yDeltaUnclamped, kPageSize.height);
    if (yDelta != yDeltaUnclamped) {
        shouldSetContentOffset = YES;
    }

    if (![self allowGoingToMapX:mapPosition_.x y:mapPosition_.y + sign(yDelta)]) {
        yDelta = 0;
        shouldSetContentOffset = YES;
    }

    if (shouldSetContentOffset) {
        baseContentOffset.y += yDelta;
        verticalScroller_.contentOffset = baseContentOffset;
    }
}

- (BOOL)allowGoingToMapX:(int)x y:(int)y {
    if (y < 0 || y > map_.count)
        return NO;
    NSArray *mapRow = map_[y];
    if (x < 0 || x > mapRow.count)
        return NO;
    return ![mapRow[x] isKindOfClass:[NSNull class]];
}

@end
