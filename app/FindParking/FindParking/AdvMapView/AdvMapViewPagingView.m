//
//  FPInfoPagingView.m
//  FindParking
//
//  Created by Leigh McCulloch on 19/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import "AdvMapViewPagingView.h"
#import "AdvMapViewInfoView.h"
#import "AdvMapViewItem.h"
#import <CoreLocation/CoreLocation.h>

@interface AdvMapViewPagingView()

@property (retain, nonatomic) NSMutableArray* infoViews;

@end

@implementation AdvMapViewPagingView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self _init];
    }
    return self;
}

- (void)awakeFromNib {
	[self _init];
}

- (void)_init {
	self.infoViews = [NSMutableArray array];
	self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"info-bar-bg"]];
}

- (void)addItem:(id<AdvMapViewItem>)item {
	// build info view
	AdvMapViewInfoView* infoView = [AdvMapViewInfoView infoViewWithItem:item];
	
	// store info view, index doesn't matter as they are ordered by their order property
	[self.infoViews addObject:infoView];
	
	// set an initial frame that puts it definitely off screen
	CGRect frame;
	frame.origin.x = -self.frame.size.width;
	frame.origin.y = 0;
	frame.size = self.frame.size;
	infoView.frame = frame;
	
	// add as subview
	[self addSubview:infoView];
	
	// update page frames and ui
	[self updateInfoViews:NO];
	[self updateContentSize];
	[self updateSelectedItem];
}

- (void)removeItem:(id<AdvMapViewItem>)item {
	for (int i=0; i<self.infoViews.count; i++) {
		AdvMapViewInfoView* infoView = [self.infoViews objectAtIndex:i];
		if ([infoView.item isEqual:item]) {
			// remove from page view
			[infoView removeFromSuperview];
			
			// remove infoview from array
			[self.infoViews removeObjectAtIndex:i];
			
			// update page frames and ui
			[self updateInfoViews:NO];
			[self updateContentSize];
			[self updateSelectedItem];
			
			// stop search, we're finished
			break;
		}
	}
}

- (void)updateAllItems {
	[self updateInfoViews:YES];
}

- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated {
	[self setContentOffset:CGPointMake(self.frame.size.width*index, 0) animated:animated];
}

- (void)scrollToItem:(id<AdvMapViewItem>)item animated:(BOOL)animated {
	[self scrollToIndex:item.order animated:animated];
}

- (void)updateInfoViews:(BOOL)updateLabels {
	id<AdvMapViewItem> selectedItem = nil;
	
	for (int i=0; i<self.infoViews.count; i++) {
		AdvMapViewInfoView* infoView = [self.infoViews objectAtIndex:i];
		
		// if this infoView is the current view on screen
		if (infoView.frame.origin.x == self.contentOffset.x) {
			selectedItem = infoView.item;
		}
		
		CGRect frame;
		frame.origin.x = self.frame.size.width * infoView.item.order;
		frame.origin.y = 0;
		frame.size = self.frame.size;
		
		infoView.frame = frame;
		
		if (updateLabels) {
			[infoView updateLabels];
		}
	}
	
	if (selectedItem) {
		[self scrollToItem:selectedItem animated:NO];
	}
}

- (void)updateContentSize {
	self.contentSize = CGSizeMake(self.frame.size.width*self.infoViews.count, self.frame.size.height);
}

- (void)updateSelectedItem {
	if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
		[self.delegate scrollViewDidEndDecelerating:self];
	}
}

- (NSUInteger)selectedIndex {
    float fractionalPage = self.contentOffset.x / self.frame.size.width;
    NSUInteger page = lround(fractionalPage);
	return page;
}

@end
