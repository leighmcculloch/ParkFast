//
//  AdvMapViewSearchBar.m
//  FindParking
//
//  Created by Leigh McCulloch on 25/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import "AdvMapViewSearchBar.h"
#import "UIImage+imageWithColor.h"

@implementation AdvMapViewSearchBar

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
	self.backgroundImage = [UIImage imageWithColor:[UIColor clearColor]];
}

@end
