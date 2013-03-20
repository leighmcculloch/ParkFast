//
//  FPInfoPagingView.h
//  FindParking
//
//  Created by Leigh McCulloch on 19/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdvMapViewInfoView.h"
#import "AdvMapViewItem.h"

@class AdvMapViewPagingView;

@protocol AdvMapViewPagingViewDelegate <UIScrollViewDelegate>

- (void)advMapViewPagingViewSelectedItemUpdate:(AdvMapViewPagingView*)pagingView;

@end

@interface AdvMapViewPagingView : UIScrollView

@property (nonatomic, assign) id<AdvMapViewPagingViewDelegate> delegate;
@property (nonatomic, readonly) NSUInteger selectedIndex;

- (void)addItem:(id<AdvMapViewItem>)item;
- (void)removeItem:(id<AdvMapViewItem>)item;
- (void)updateAllItems;
- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)scrollToItem:(id<AdvMapViewItem>)item animated:(BOOL)animated;

@end
